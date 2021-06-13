# Package

version       = "0.1.0"
author        = "Florian Schroedl"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["rofi_org_bookmarks"]
binDir        = "./dst"


# Dependencies

requires "nim >= 1.4.4"
requires "nimfp >= 0.4.5"
requires "cligen >= 1.5.4"
requires "tempfile >= 0.1.7"

# Tasks

proc test(flags, path: string) =
  if not dirExists "build":
    mkDir "build"
  # Note: we compile in release mode. This still have stacktraces
  #       but is much faster than -d:debug

  # Compilation language is controlled by TEST_LANG
  var lang = "c"
  if existsEnv"TEST_LANG":
    lang = getEnv"TEST_LANG"

  exec "nim " & lang & " " & flags & " --verbosity:0 --hints:off --warnings:off --threads:on -d:release --stacktrace:on --linetrace:on --outdir:build -r " & path

task test, "Run cpu tests":
  test "", "./tests/test.nim"

# Nixos

import distros
if detectOs(NixOS):
  foreignDep "pkgconfig"
