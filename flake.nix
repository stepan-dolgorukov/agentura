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
      agents = builtins.mapAttrs (
        _: file: pkgs.newScope { inherit ponytail; } file { }
      ) {
        antigravity = ./antigravity.nix;
        claude = ./claude.nix;
        grok = ./grok.nix;
      };
      shell = names: pkgs.mkShellNoCC {
        packages = map (name: agents.${name}) names;
      };
    in
    {
      packages.x86_64-linux = agents;
      devShells.x86_64-linux = {
        default = shell [
          "antigravity"
          "claude"
          "grok"
        ];
        antigravity = shell [ "antigravity" ];
        claude = shell [ "claude" ];
        grok = shell [ "grok" ];
      };
    };
}
