import os, sys
from pathlib import Path
import tomlkit

path = Path(sys.argv[1])
keys = ("disable_workspace_teleport", "disable_codebase_upload")

if path.is_symlink():
    print(f"grok: {path} — симлинк, не изменяю его", file=sys.stderr)
    raise SystemExit(0)
try:
    text = path.read_text() if path.exists() else None
except OSError as err:
    print(f"grok: не удалось прочитать {path}: {err}", file=sys.stderr)
    raise SystemExit(0)
if text is None:
    doc = tomlkit.document()
else:
    try:
        doc = tomlkit.parse(text)
    except Exception:
        print(f"grok: не удалось разобрать {path}, harness не изменён", file=sys.stderr)
        raise SystemExit(0)

harness = doc.get("harness")
if harness is None:
    harness = tomlkit.table()
    doc["harness"] = harness
elif not isinstance(harness, dict):
    print(f"grok: {path} [harness] не таблица, не изменяю его", file=sys.stderr)
    raise SystemExit(0)
if all(harness.get(key) is True for key in keys):
    raise SystemExit(0)
for key in keys:
    harness[key] = True

path.parent.mkdir(parents=True, exist_ok=True)
tmp = path.with_name(f".{path.name}.tmp")
try:
    tmp.write_text(tomlkit.dumps(doc))
    os.replace(tmp, path)
except OSError as err:
    print(f"grok: не удалось записать {path}: {err}", file=sys.stderr)
    try:
        tmp.unlink()
    except OSError:
        pass
