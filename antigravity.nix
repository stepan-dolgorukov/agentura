{
  fetchurl,
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
in
package
