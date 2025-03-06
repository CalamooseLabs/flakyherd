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
            # Create the settings JSON file
            defaultSettings = pkgs.writeTextFile {
              name = "default-settings.json";
              text = builtins.toJSON settings;
            };

            # Create a script to prepare the config
            setupScript = pkgs.writeShellScript "setup-zed-config" ''
              # Create a temporary directory for this session
              TEMP_DIR=$(mktemp -d)

              # Create the proper config structure
              mkdir -p "$TEMP_DIR/zed"

              # Copy the default settings to the temp directory
              cp ${defaultSettings} "$TEMP_DIR/zed/settings.json"
              chmod 644 "$TEMP_DIR/zed/settings.json"

              # If user has custom settings, merge them
              USER_SETTINGS="$HOME/.config/zed/settings.json"
              if [ -f "$USER_SETTINGS" ]; then
                ${pkgs.jq}/bin/jq -s ".[0] * .[1]" "$TEMP_DIR/zed/settings.json" "$USER_SETTINGS" > "$TEMP_DIR/zed/merged.json"
                chmod 644 "$TEMP_DIR/zed/merged.json"
                cp "$TEMP_DIR/zed/merged.json" "$TEMP_DIR/zed/settings.json"
                rm "$TEMP_DIR/zed/merged.json"
              fi

              # Copy any user themes if they exist
              if [ -d "$HOME/.config/zed/themes" ]; then
                mkdir -p "$TEMP_DIR/zed/themes"
                cp -r "$HOME/.config/zed/themes"/* "$TEMP_DIR/zed/themes/" 2>/dev/null || true
              fi

              # Clean up temp directory when shell exits
              trap "rm -rf \"$TEMP_DIR\"" EXIT

              # Export the config directory
              echo "$TEMP_DIR"
            '';
          in
          pkgs.stdenv.mkDerivation {
            pname = "zed-editor-wrapper";
            version = "1.0.0";

            # Add an empty src to satisfy the requirement
            src = pkgs.emptyDirectory;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            buildInputs = [ pkgs.zed-editor ];

            installPhase = ''
              mkdir -p $out/bin

              makeWrapper ${pkgs.zed-editor}/bin/zeditor $out/bin/zeditor \
                --run "export XDG_CONFIG_HOME=\$(${setupScript})" \
                --set ZED_WRAPPED 1
            '';
          };

        # Set the default package to be a wrapper with empty settings
        default = zed-wrapper {};
      };
    };
}
