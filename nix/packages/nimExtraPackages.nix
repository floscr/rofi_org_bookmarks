{ pkgs, nimpkgs, ... }:

with pkgs;
{
  fusion =
    (fetchFromGitHub
      ({
        owner = "nim-lang";
        repo = "fusion";
        rev = "v1.1";
        sha256 = "9tn0NTXHhlpoefmlsSkoNZlCjGE8JB3eXtYcm/9Mr0I=";
      }));
  nimfp = with nimpkgs; [
    (pkgs.fetchFromGitHub
      ({
        owner = "floscr";
        repo = "nimfp";
        rev = "master";
        sha256 = "sha256-gEs4qovho5qTXCquEG+fZOsL3rGB+Ql/r0IeLhnHjFk=";
      }))
    classy
    nimboost
  ];
}
