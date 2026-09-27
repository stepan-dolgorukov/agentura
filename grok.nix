{
  symlinkJoin,
  makeShellWrapper,
  ponytail,
  fetchurl,
  writeShellScript,
  grok-build,
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

  installPonytail = writeShellScript "grok-install-ponytail" ''
    grok=${package}/bin/grok
    case "$("$grok" plugin list 2>/dev/null)" in
      *${ponytail}*) ;;
      *)
        "$grok" plugin uninstall ponytail >/dev/null 2>&1
        "$grok" plugin install ${ponytail} --trust >/dev/null 2>&1 &&
          "$grok" plugin enable ponytail >/dev/null 2>&1 ||
          echo "grok: не удалось установить плагин ponytail" >&2
        ;;
    esac
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
        --run ${installPonytail}
    done
  '';
}
