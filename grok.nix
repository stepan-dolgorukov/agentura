{
  lib,
  symlinkJoin,
  makeShellWrapper,
  ponytail,
  fetchurl,
  writeShellScript,
  jq,
  grok-build,
  python3,
}:
let
  version = "1.0.41";
  hash = "sha256-nOA+0j4W6gEHK0SWJj1iE6J4meHj4QfwCNNu34LnBAc=";

  package = grok-build.overrideAttrs {
    inherit version;
    src = fetchurl {
      url = "https://x.ai/cli/grok-${version}-linux-x86_64";
      inherit hash;
    };
  };

  # [harness] через GROK_CONFIG не принимается — только config.toml.
  privacyConfig = writeShellScript "grok-privacy-config" ''
    cfg="''${GROK_HOME:-$HOME/.grok}/config.toml"
    ${python3.withPackages (ps: [ ps.tomlkit ])}/bin/python - "$cfg" <<'PY'
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
if all(harness.get(key) == True for key in keys):
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
PY
  '';

  installPonytail = writeShellScript "grok-install-ponytail" ''
    grok=${package}/bin/grok
    src=${ponytail}
    if ! list=$("$grok" plugin list --json 2>/dev/null); then
      echo "grok: не удалось прочитать список плагинов" >&2
      exit 0
    fi
    if printf '%s' "$list" | ${lib.getExe jq} -e --arg src "$src" 'any(.[]; .source == $src)' >/dev/null; then
      exit 0
    fi
    "$grok" plugin uninstall ponytail >/dev/null 2>&1 || true
    "$grok" plugin install "$src" --trust >/dev/null 2>&1 &&
      "$grok" plugin enable ponytail >/dev/null 2>&1 ||
      echo "grok: не удалось установить плагин ponytail" >&2
  '';
in
symlinkJoin {
  inherit (package) name;
  paths = [ package ];
  nativeBuildInputs = [ makeShellWrapper ];
  postBuild = ''
    for bin in grok agent; do
      wrapProgram $out/bin/$bin \
        --set GROK_TELEMETRY_ENABLED false \
        --set GROK_TELEMETRY_MIXPANEL_ENABLED false \
        --set GROK_TELEMETRY_TRACE_UPLOAD false \
        --set GROK_ERROR_REPORTING false \
        --set GROK_FEEDBACK_ENABLED false \
        --set GROK_MEMORY false \
        --set GROK_DISABLE_AUTOUPDATER 1 \
        --set GROK_CAMPAIGNS 0 \
        --set GROK_PROMPT_SUGGESTIONS 0 \
        --set GROK_TITLE_REFRESH 0 \
        --set GROK_TURN_SUMMARY 0 \
        --set GROK_SESSION_RECAP 0 \
        --set GROK_RESPECT_GITIGNORE 1 \
        --run ${privacyConfig} \
        --run ${installPonytail}
    done
  '';
}
