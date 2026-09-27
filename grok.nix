{
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
package
