{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ponytail = {
      url = "github:DietrichGebert/ponytail/v4.10.0";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ponytail, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShellNoCC {
        packages = map (agent: pkgs.newScope { inherit ponytail; } agent { }) [
          ./antigravity.nix
          ./claude.nix
          ./grok.nix
        ];
      };
    };
}
