{
  lib,
  symlinkJoin,
  makeShellWrapper,
  ponytail,
  fetchurl,
  writeShellApplication,
  writeText,
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
      url = "https://storage.googleapis.com/grok-build-public-artifacts/cli/grok-${version}-linux-x86_64";
      inherit hash;
    };
  };

  privacyScript = writeText "grok-privacy.py" (builtins.readFile ./grok-privacy.py);

  # [harness] через GROK_CONFIG не принимается — только config.toml.
  privacyConfig = writeShellApplication {
    name = "grok-privacy-config";
    text = ''
      cfg="''${GROK_HOME:-$HOME/.grok}/config.toml"
      ${python3.withPackages (ps: [ ps.tomlkit ])}/bin/python ${privacyScript} "$cfg"
    '';
  };

  installPonytail = writeShellApplication {
    name = "grok-install-ponytail";
    text = ''
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
  };
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
        --set GROK_THEME terminal \
        --set GROK_TERMINAL_THEME 1 \
        --run ${lib.getExe privacyConfig} \
        --run ${lib.getExe installPonytail}
    done
  '';
}
