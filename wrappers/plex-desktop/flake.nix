{
  description = "Plex desktop fix for hyprland and stylix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; };
    in {
      packages.${system}.default = pkgs.symlinkJoin {
        name = "plex-desktop-fixed";
        paths = [ pkgs.plex-desktop ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/plex-desktop \
            --set QT_STYLE_OVERRIDE ""
        '';
      };
    };
}
