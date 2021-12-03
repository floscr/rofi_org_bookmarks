{
  description = "Search bookmarks saved in org documents with rofi";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.nimble.url = "github:floscr/flake-nimble";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { self
    , nixpkgs
    , nimble
    , nixos
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      linguist = pkgs.callPackage ./nix/packages/linguist { };
      nimpkgs = nimble.packages.${system};
      customNimPkgs = import ./nix/packages/nimExtraPackages.nix { inherit pkgs; inherit nimpkgs; };

      customEmacs = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages
        (epkgs: with epkgs.melpaStablePackages; [
          org-web-tools
        ]);
      buildInputs = with pkgs; [
        customEmacs
        linguist
      ];
      utils = import ./nix/lib/nimBuildGenerator.nix;
      inherit (nixos.lib) flatten;
    in
    rec {
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
            linguist
          ];

          buildInputs = buildInputs;

          buildPhase = utils.makeNimBuildScript {
            srcFile = "./src/${pkgName}.nim";
            dstName = pkgName;
            packages = flatten [
              (with nimpkgs; [
                argparse
                colorize
              ])
              customNimPkgs.fusion
              customNimPkgs.nimfp
            ];
            extraLines = [
              ''-d:LINGUIST_BIN_PATH="${linguist}/bin/linguist"''
              ''-d:EMACS_BIN_PATH="${customEmacs}/bin/emacs"''
              ''-d:EMACS_INIT_FILE_PATH="${placeholder "out"}"''
              ""
            ];
          };

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
