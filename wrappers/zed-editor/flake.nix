{
  description = "Zed Editor with local configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      packages.x86_64-linux = rec {
        zed-wrapper = settings:
          let
            # Create the settings JSON file outside the derivation
            settingsJson = pkgs.writeTextFile {
              name = "zed-settings.json";
              text = builtins.toJSON settings;
            };
          in
          pkgs.stdenv.mkDerivation {
            pname = "zed-editor-wrapper";
            version = "1.0.0";

            # Add an empty src to satisfy the requirement
            src = pkgs.emptyDirectory;

            buildInputs = [ pkgs.makeWrapper pkgs.jq pkgs.zed-editor ];

            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/.config/zed

              # Copy the settings file to the build directory
              cp ${settingsJson} $out/.config/zed/settings.json

              # Create the zed wrapper with inline configuration
              makeWrapper ${pkgs.zed-editor}/bin/zeditor $out/bin/zeditor \
                --set XDG_CONFIG_HOME "$out/.config" \
                --run '
                  # Create a temporary directory for merged settings
                  TEMP_DIR=$(mktemp -d)
                  TEMP_SETTINGS="$TEMP_DIR/settings.json"

                  # Copy our base settings to the temp location
                  cp "$XDG_CONFIG_HOME/zed/settings.json" "$TEMP_SETTINGS"

                  # If user has custom settings, merge them
                  USER_SETTINGS="$HOME/.config/zed/settings.json"
                  if [ -f "$USER_SETTINGS" ]; then
                    ${pkgs.jq}/bin/jq -s ".[0] * .[1]" "$TEMP_SETTINGS" "$USER_SETTINGS" > "$TEMP_DIR/merged.json"
                    mv "$TEMP_DIR/merged.json" "$TEMP_SETTINGS"
                  fi

                  # Copy any user themes if they exist
                  if [ -d "$HOME/.config/zed/themes" ]; then
                    mkdir -p "$XDG_CONFIG_HOME/zed/themes"
                    cp -r "$HOME/.config/zed/themes"/* "$XDG_CONFIG_HOME/zed/themes/" 2>/dev/null || true
                  fi

                  # Use the temporary settings file for this session
                  export ZED_SETTINGS_PATH="$TEMP_SETTINGS"
                '
            '';
          };

        # Set the default package to be a wrapper with empty settings
        default = zed-wrapper {};
      };
    };
}
