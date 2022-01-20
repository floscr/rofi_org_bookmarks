# Package

version       = "1.0.0"
author        = "Florian Schroedl"
description   = "Search bookmarks saved in org documents with rofi"
license       = "MIT"
srcDir        = "src"
bin           = @["rofi_org_bookmarks"]
binDir        = "./dst"


requires "nim >= 1.4.4"
requires "https://github.com/floscr/nimfp#master"
requires "cligen >= 1.5.4"
requires "zero_functional"
requires "print"
requires "fusion"
requires "argparse >= 3.0.0"
requires "colorize"

import distros
if detectOs(NixOS):
  foreignDep "pkgconfig"
