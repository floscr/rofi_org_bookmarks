{ lib, fetchFromGitHub, python37Packages, glib, cairo, pango, pkg-config, libxcb, xcbutilcursor }:

python37Packages.buildPythonApplication rec {
  name = "guesslang";
  version = "2.2.1";

  src = builtins.fetchTarball {
    url = https://github.com/yoeo/guesslang/archive/refs/tags/v2.2.1.tar.gz;
    sha256 = "14r10pjm4x1n573kxm31pwxlzvz9lrf6y18ywikf6i21yh5kipwq";
  };

  pythonPath = with python37Packages; [
    tensorflow
  ];

}
