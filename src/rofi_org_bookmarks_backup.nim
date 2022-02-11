import std/collections/sequtils
import argparse
import ./lib/backup_bookmarks_main

{.experimental: "caseStmtMacros".}

proc runCli(args = commandLineParams()): auto =
  var p = newParser:
    option("--output")
    arg("urls", nargs = -1)
    run:
      echo backupBookmarks(
        urls = opts.urls,
        output = opts.outputOpt,
      )

  try:
    if args.len == 0:
      echo p.help
      quit(0)

    p.run(args)
  except UsageError as e:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

when isMainModule:
  runCli()
