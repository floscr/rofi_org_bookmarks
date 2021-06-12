{ pkgs, nimpkgs, buildInputs }:

pkgs.mkShell {
  shellHook = ''
    export NIMBLE_DIR="$PWD/.nimble"
  '';
  buildInputs = with pkgs; buildInputs ++ [
    nim
    nimlsp
  ];
}
