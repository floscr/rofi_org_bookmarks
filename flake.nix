{
  description = "A simple example of managing a project with a flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.nimble.url = "github:floscr/flake-nimble";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, nimble, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
          nimpkgs = nimble.packages.${system};
          buildInputs = with pkgs; [
            imagemagick
            ocrmypdf
            scantailor
            qpdf
          ];
      in rec {
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
                -p:${ocrmypdf}/bin \
                -p:${nimpkgs.cligen}/src \
                -p:${nimpkgs.nimboost}/src \
                -p:${nimpkgs.classy}/src \
                -p:${nimpkgs.nimfp}/src \
                -p:${nimpkgs.tempfile}/src \
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
