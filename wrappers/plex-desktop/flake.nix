{
  description = "Plex desktop fix for hyprland and stylix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    {
      packages.x86_64-linux = {
        plex-desktop = nixpkgs.lib.mkShell {
          buildInputs = [ nixpkgs.makeWrapper nixpkgs.jq nixpkgs.zed-editor ];
          shellHook = ''
            mkdir -p $out/bin

            makeWrapper ${pkgs.plex-desktop}/bin/plex-desktop $out/bin/plex-desktop \
              --set QT_STYLE_OVERRIDE ""
          '';
        };

        default = plex-desktop;
      };
    };
}
