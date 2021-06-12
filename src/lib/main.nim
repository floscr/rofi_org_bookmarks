import fp/either
import fp/option
import os
import streams
import strformat
import strutils
import sugar
import utils

const FILE = "~/Documents/Org/Bookmarks/bookmarks.org"

proc readHeadlineItems(file = FILE): (seq[string], seq[string]) =
  let strm = newFileStream(file.expandTilde, fmRead, 1)
  var line = ""

  var titles: seq[string] = @[]
  var urls: seq[string] = @[]

  var url = string.none

  if not isNil(strm):
    while strm.readLine(line):
      if line.startsWith("** "):
        line.removePrefix("** ")
        titles.insert(line.replace("\"", "\\\""), 0)
        # Keep the same index as title by inserting empty string when no url is defined
        urls.insert(url.getOrElse(""), 0)
        url = string.none
      if line.startsWith(":URL: "):
        line.removePrefix(":URL:")
        line.removePrefix({' '})
        url = line.some

    urls.insert(url.getOrElse(""), 0)

    strm.close()

  (titles, urls)

proc main*(): string =
  let (titles, urls) = readHeadlineItems()
  echo urls.join("\n")
  let rofiInput = titles.join("\n")
  let index = sh(&"echo \"{rofiInput}\" | rofi -i -levenshtein-sort -dmenu -p \"Run\" -format i")

  index
    .map((x) => x.replace("\n", ""))
    .map(parseInt)
    .map((x) => urls[x])
    .map((x) => x.replace("\"", "\\\""))
    .tap((x: string) => execShellCmd(&"xdg-open {x}"))
    .fold(e => e, v => $v)
