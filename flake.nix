{
  description = "Programming Language Foundations in Agda (PLFA)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Nixpkgs wraps Agda with a hardcoded `--library-file` that points to a
        # read-only empty directory if you don't use agda.withPackages. This overrides
        # our local AGDA_DIR. We extract the raw binary and GHC path from the wrapper
        # to build a clean version.
        myAgda = pkgs.runCommand "agda" { buildInputs = [ pkgs.makeWrapper ]; } ''
          mkdir -p $out/bin
          RAW_BIN=$(grep -o '^exec "[^"]*"' ${pkgs.agda}/bin/agda | cut -d'"' -f2)
          GHC_BIN=$(grep -o -e '--with-compiler=[^ ]*' ${pkgs.agda}/bin/agda | cut -d'=' -f2)
          makeWrapper "$RAW_BIN" $out/bin/agda --add-flags "--with-compiler=$GHC_BIN"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            myAgda
            pkgs.julia-mono
            pkgs.git
          ];

          shellHook = ''
            # Materialize Agda's library config outside the project tree so the
            # source dir stays clean. Files are regenerated on every shell entry.
            export AGDA_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/agda/plfa"
            mkdir -p "$AGDA_DIR"

            echo "$PWD/standard-library/standard-library.agda-lib" > "$AGDA_DIR/libraries"
            echo "$PWD/src/plfa.agda-lib" >> "$AGDA_DIR/libraries"

            echo "standard-library" > "$AGDA_DIR/defaults"
            echo "plfa" >> "$AGDA_DIR/defaults"

            echo "=== PLFA Environment Loaded ==="
            echo "Agda $(agda --version) is available."
            echo "Run 'code .' to open VSCode (with agda-mode extension installed globally)."
            echo "In VSCode: Ctrl+Shift+P → Agda: Load to type-check."
            echo "AGDA_DIR=$AGDA_DIR"
          '';
        };
      }
    );
}
