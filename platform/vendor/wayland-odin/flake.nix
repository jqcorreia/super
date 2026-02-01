{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      odin_updated = pkgs.odin.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "dev-2025-01";
          src = pkgs.fetchFromGitHub {
            owner = "odin-lang";
            repo = "Odin";
            rev = "2aae4cfd461860bd10dcb922f867c98212a11449";
            hash = "sha256-GXea4+OIFyAhTqmDh2q+ewTUqI92ikOsa2s83UH2r58=";
          };
        }
      );
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          wayland
          wayland-scanner
          wayland-protocols
          gdb
          seer
          # odin
          odin_updated
          libGL
        ];
        shellHook = "zsh";
        name = "odin dev shell";
      };
    };
}
