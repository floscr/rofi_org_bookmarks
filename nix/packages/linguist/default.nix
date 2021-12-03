{ pkgs, stdenv, lib, bundlerEnv, ruby, fetchFromGitHub, nodejs }:
# nix-shell --command "bundler install && bundix" in the clone, copy gemset.nix, Gemfile and Gemfile.lock
let
  json = ./samples.json;
  gems = bundlerEnv {
    name = "linguist-env";
    inherit ruby;
    gemdir = ./.;
    gemConfig = pkgs.defaultGemConfig // {
      nokogiri = attrs: {
        buildInputs = with pkgs; [ pkgconfig zlib.dev ];
      };
    };
  };
in
stdenv.mkDerivation {
  name = "linguist";
  src = fetchFromGitHub {
    owner = "github";
    repo = "linguist";
    rev = "v7.18.0";
    sha256 = "Jv6DDof33hJF0q/6LyCMeVNWI7fvknyZ8dTLrAIR7pQ=";
  };
  buildInputs = with pkgs; [ gems ruby libxml2 ];
  dontPatchShebangs = "1";
  buildPhase = "cp ${json} $TMPDIR/samples.json";
  installPhase = ''
    mkdir -p $out/{bin,share/linguist}

    cp -r * $out/share
    cp $TMPDIR/samples.json $out/share/lib/linguist/samples.json

    bin=$out/bin/linguist

    cat > $bin <<EOF
#! ${stdenv.shell} -e
exec ${gems}/bin/bundle exec ${ruby}/bin/ruby $out/share/bin/github-linguist "\$@"

EOF
    chmod +x $bin
  '';
}
