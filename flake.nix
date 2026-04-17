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
        
        myEmacs = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (epkgs: [ epkgs.agda2-mode ]);
        
        # Wrap Agda to explicitly pass the local libraries file,
        # overriding the Nixpkgs hardcoded global library wrapper.
        myAgda = pkgs.writeShellScriptBin "agda" ''
          exec ${pkgs.agda}/bin/agda --library-file="$PWD/.agda/libraries" "$@"
        '';
        
        plfa-emacs = pkgs.writeShellScriptBin "plfa-emacs" ''
          mkdir -p "$PWD/.agda"
          cat << 'ELISP' > "$PWD/.agda/plfa-init.el"
          (setq auto-mode-alist
            (append
              '(("\\.agda\\'" . agda2-mode)
                ("\\.lagda.md\\'" . agda2-mode))
              auto-mode-alist))
          (setq agda2-program-name "${myAgda}/bin/agda")
ELISP
          exec ${myEmacs}/bin/emacs -l "$PWD/.agda/plfa-init.el" "$@"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            myAgda
            myEmacs
            plfa-emacs
            pkgs.julia-mono
            pkgs.git
          ];

          shellHook = ''
            export AGDA_DIR="$PWD/.agda"
            mkdir -p "$AGDA_DIR"
            
            echo "$PWD/standard-library/standard-library.agda-lib" > "$AGDA_DIR/libraries"
            echo "$PWD/src/plfa.agda-lib" >> "$AGDA_DIR/libraries"
            
            echo "standard-library" > "$AGDA_DIR/defaults"
            echo "plfa" >> "$AGDA_DIR/defaults"

            echo "=== PLFA Environment Loaded ==="
            echo "Agda $(agda --version) and Emacs (with agda2-mode) are available."
            echo "Run 'plfa-emacs <file>' to open an Agda file with the correct modes loaded."
            echo "Example: plfa-emacs src/plfa/part1/Naturals.lagda.md"
          '';
        };
      }
    );
}
