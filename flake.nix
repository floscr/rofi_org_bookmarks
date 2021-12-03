{
  description = "Search bookmarks saved in org documents with rofi";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.nimble.url = "github:floscr/flake-nimble";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, nimble, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nimpkgs = nimble.packages.${system};
        customEmacs = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages
          (epkgs: with epkgs.melpaStablePackages; [
            org-web-tools
          ]);
        buildInputs = with pkgs; [
          customEmacs
        ];
      in
      rec {

        packages.guesslang = pkgs.callPackage ./packages/guesslang.nix { };

        packages.rofi_org_bookmarks_backup =
          let
            pkgName = "rofi_org_bookmarks_backup";
          in
          pkgs.stdenv.mkDerivation {
            name = pkgName;
            src = ./.;

            nativeBuildInputs = with pkgs; [
              nim
              customEmacs
            ];

            buildInputs = buildInputs;

            buildPhase = with pkgs; let
              customNimPkgs = {
                fusion = pkgs.fetchFromGitHub
                  ({
                    owner = "nim-lang";
                    repo = "fusion";
                    rev = "v1.1";
                    sha256 = "9tn0NTXHhlpoefmlsSkoNZlCjGE8JB3eXtYcm/9Mr0I=";
                  });
                nimfp = pkgs.fetchFromGitHub
                  ({
                    owner = "floscr";
                    repo = "nimfp";
                    rev = "master";
                    sha256 = "sha256-gEs4qovho5qTXCquEG+fZOsL3rGB+Ql/r0IeLhnHjFk=";
                  });
              };
            in
            ''
              HOME=$TMPDIR
              # Pass paths of needed buildInputs
              # and nim packages fetched from nix
              nim compile \
                  -d:release \
                  --verbosity:0 \
                  --hint[Processing]:off \
                  --excessiveStackTrace:on \
                  -d:EMACS_BIN_PATH="${customEmacs}/bin/emacs" \
                  -d:EMACS_INIT_FILE_PATH="${placeholder "out"}" \
                  -p:${customNimPkgs.fusion}/src \
                  -p:${customNimPkgs.nimfp}/src \
                  -p:${nimpkgs.argparse}/src \
                  -p:${nimpkgs.classy}/src \
                  -p:${nimpkgs.cligen}/src \
                  -p:${nimpkgs.nimboost}/src \
                  --out:$TMPDIR/${pkgName} \
                  ./src/${pkgName}.nim
            '';
            installPhase = ''
              mkdir -p $out/lib
              cp ./src/rofi_org_bookmarks_backup.el $out/lib.el
              install -Dt \
              $out/bin \
              $TMPDIR/${pkgName}
            '';
          };

        packages.rofi_org_bookmarks = pkgs.stdenv.mkDerivation {
          name = "rofi_org_bookmarks";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            nim
            pkgconfig
          ];

          buildInputs = buildInputs;

          buildPhase = with pkgs; ''
            HOME=$TMPDIR
            # Pass paths of needed buildInputs
            # and nim packages fetched from nix
            nim compile \
                -d:release \
                --verbosity:0 \
                --hint[Processing]:off \
                --excessiveStackTrace:on \
                -p:${nimpkgs.cligen}/src \
                -p:${nimpkgs.nimboost}/src \
                -p:${nimpkgs.classy}/src \
                -p:${nimpkgs.nimfp}/src \
                --out:$TMPDIR/rofi_org_bookmarks \
                ./src/rofi_org_bookmarks.nim
          '';
          installPhase = ''
            install -Dt \
            $out/bin \
            $TMPDIR/rofi_org_bookmarks
          '';
        };

        devShell = import ./shell.nix {
          inherit pkgs;
          inherit nimpkgs;
          inherit buildInputs;
        };

        defaultPackage = packages.rofi_org_bookmarks;

      });
}
