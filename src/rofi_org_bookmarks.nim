import cligen
import lib/main
import os
import osproc
import strformat

const FILE = "~/Documents/Org/Bookmarks/bookmarks.org"

proc cli(file=FILE, prettyPrint=true, reverse=true): void =

  let f = file.expandTilde
  if not f.fileExists:
    echo &"Error: Passed file \"{file}\" does not exist."
    quit(QuitFailure)

  echo main(
    Config(
      file: file,
      prettyPrint: prettyPrint,
      reverse: reverse
  ))

dispatch(cli, help = {
  "file": """The file locations of your bookmarks.org""",
  "prettyPrint": """Pretty print rofi lines""",
  "reverse": """Reverse lines order""",
})
