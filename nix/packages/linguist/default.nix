{ pkgs, stdenv, lib, bundlerEnv, ruby, fetchFromGitHub, nodejs }:
# nix-shell --command "bundler install && bundix" in the clone, copy gemset.nix, Gemfile and Gemfile.lock
let
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
  installPhase = ''
    mkdir -p $out/{bin,share/linguist}

    set dontPatchShebangs=1
    cp -r * $out/share

    # set the default db path, unfortunately setting to /tmp does not seem to work
    # sed -i 's#db_file: .*#db_file: "/tmp/linguist.db"#' $out/share/linguist/config.yaml

    bin=$out/bin/linguist
    cat > $bin <<EOF
#! ${stdenv.shell} -e
exec ${gems}/bin/bundle exec ${ruby}/bin/ruby $out/share/bin/github-linguist "\$@"

EOF
    chmod +x $bin
  '';
}
