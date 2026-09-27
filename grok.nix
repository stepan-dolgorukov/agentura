{
  symlinkJoin,
  makeShellWrapper,
  fetchurl,
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
        --set GROK_FEEDBACK_ENABLED false
    done
  '';
}
