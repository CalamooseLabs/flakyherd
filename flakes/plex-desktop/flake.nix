{
  description = "Plex desktop fix for hyprland and stylix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    packages.${system}.default = pkgs.symlinkJoin {
      name = "plex-desktop-fixed";
      paths = [pkgs.plex-desktop];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/plex-desktop \
          --set QT_STYLE_OVERRIDE "" \
          --set NIXOS_XDG_OPEN_USE_PORTAL 1
      '';
    };
  };
}
