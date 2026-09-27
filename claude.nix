{
  claude-code,
}:
let
  version = "2.1.274";
  binary = "claude.zst";
  checksum = "ea049d5d46d5e6deaaadef9549f45879917d39a196d912c99bd3981a0cfdc7d8";

  package = claude-code.override {
    manifest = {
      inherit version;
      platforms.linux-x64 = { inherit binary checksum; };
    };
  };
in
package
