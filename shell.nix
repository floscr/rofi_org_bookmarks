{ pkgs, nimpkgs, buildInputs }:

pkgs.mkShell {
  shellHook = ''
    export NIMBLE_DIR="$PWD/.nimble"
    export PATH=$NIMBLE_DIR/bin:$PATH
  '';
  buildInputs = with pkgs; buildInputs ++ [
    nim
    nimlsp
  ];
}
