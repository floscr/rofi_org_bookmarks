import std/collections/sequtils
import argparse
import ./lib/backup_bookmarks_main

{.experimental: "caseStmtMacros".}

proc runCli(args = commandLineParams()): auto =
  var p = newParser:
    option("-o", "--output", help = "The output file, forwards to pandocs -o option, so the extension defines the format.")
    option("-t", "--title", help = "The title of the output file, default to output file name.")
    option("--scraper", default = some("readable"), choices = @["emacs", "readable"], help = "Choice of scraper to fetch the webpage.")
    flag("--send-to-device", help = "Directly send to device")
    arg("urls", nargs = -1)
    run:
      echo backupBookmarks(
        urls = opts.urls,
        output = opts.outputOpt,
        title = opts.titleOpt,
        scraper = opts.scraper,
        sendToDevice = opts.sendToDevice,
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
