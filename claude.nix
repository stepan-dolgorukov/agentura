{
  symlinkJoin,
  makeShellWrapper,
  ponytail,
  claude-code,
  nodejs,
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
symlinkJoin {
  inherit (package) name;
  paths = [ package ];
  nativeBuildInputs = [ makeShellWrapper ];
  postBuild = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_TELEMETRY 1 \
      --set DISABLE_ERROR_REPORTING 1 \
      --set CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY 1 \
      --set DISABLE_FEEDBACK_COMMAND 1 \
      --set DISABLE_BUG_COMMAND 1 \
      --set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1 \
      --set CLAUDE_CODE_DISABLE_AUTO_MEMORY 1 \
      --add-flags "--plugin-dir ${ponytail}" \
      --prefix PATH : ${nodejs}/bin
  '';
}
