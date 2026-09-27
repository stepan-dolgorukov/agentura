{
  lib,
  symlinkJoin,
  makeShellWrapper,
  fetchurl,
  writeShellScript,
  jq,
  antigravity-cli,
}:
let
  version = "1.2.12";
  build = "4585245538910208";
  sha512 = "8604c5a68ca6242d93eaec24b77c56cd71d62d61b832323cb9fd01aebcfff3360cf875d0066c7c48efbe238fb383b0dc3b2f24b4f23de784da7758fc35009b7c";

  package = antigravity-cli.overrideAttrs {
    inherit version;
    src = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-${build}/linux-x64/cli_linux_x64.tar.gz";
      inherit sha512;
    };
  };

  config = {
    ".gemini/config/config.json".telemetryEnabled = false;
    ".gemini/antigravity-cli/settings.json".showFeedbackSurvey = false;
  };

  enforceConfig = writeShellScript "agy-enforce-config" ''
    merge() {
      local file="$HOME/$1" overrides="$2" tmp
      local jq=${lib.getExe jq}

      if [ -s "$file" ] && "$jq" -e --argjson o "$overrides" \
           '. as $s | $o | to_entries | all(.value == $s[.key])' "$file" >/dev/null 2>&1; then
        return
      fi
      if [ -L "$file" ]; then
        echo "agy: $file — симлинк, не изменяю его; выставьте в нём вручную: $overrides" >&2
        return
      fi

      mkdir -p "$(dirname "$file")"
      [ -s "$file" ] || echo '{}' >"$file"
      tmp=$(mktemp "$file.XXXXXX")
      if "$jq" --argjson o "$overrides" '. + $o' "$file" >"$tmp"; then
        mv "$tmp" "$file"
      else
        echo "agy: не удалось разобрать $file, в нём НЕ выставлено: $overrides" >&2
        rm -f "$tmp"
      fi
    }

    ${lib.concatStrings (
      lib.mapAttrsToList (file: overrides: ''
        merge ${lib.escapeShellArg file} ${lib.escapeShellArg (builtins.toJSON overrides)}
      '') config
    )}
  '';
in
symlinkJoin {
  inherit (package) name;
  paths = [ package ];
  nativeBuildInputs = [ makeShellWrapper ];
  postBuild = ''
    wrapProgram $out/bin/agy \
      --run ${enforceConfig}
  '';
}
