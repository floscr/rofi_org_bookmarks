import cligen
import lib/main
import os
import strformat

const FILE = "~/Documents/Org/Bookmarks/bookmarks.org"

proc rofi_org_bookmarks(file=FILE): void =
  let f = file.expandTilde
  if not f.fileExists:
    echo &"Error: Passed file \"{file}\" does not exist."
    quit(QuitFailure)

  echo main(
    Config(
      file: f,
  ))

dispatch(rofi_org_bookmarks, help = {
  "file": """The file locations of your bookmarks.org""",
})
