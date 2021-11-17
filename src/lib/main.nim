import fp/either
import fp/option
import os
import streams
import strformat
import strutils
import sugar
import utils

const TMP_FILE_NAME = "rofi_org_bookmarks"
let cacheFile = getCacheDir().joinPath(TMP_FILE_NAME)

type
  Config* = ref object
    file*: string

proc parseTags*(line: string): (string, Option[string]) =
  if not line.endsWith(":"):
    return (line, string.none)

  let x = rsplit(line, " ", maxsplit = 1)
  let left = x[0]
  let right = x[1]

  (left, right.some.notEmpty)

proc markupLine*(x: (string, Option[string])): string =
  let (headline, tags) = x

  let markupTags = tags
    .map((x: string) => &"<span gravity=\"east\" size=\"x-small\" font_style=\"italic\" foreground=\"#5c606b\"> {x}</span>")
    .getOrElse("")
  &"<span>{headline}</span>{markupTags}"

proc prepareLine(x: string): string =
  var line = x
  line.removePrefix("** ")
  line
    .parseTags()
    .markupLine()
    .replace("&", "&amp;")

proc readHeadlineItems(cfg: Config): (seq[string], seq[string]) =
  let strm = newFileStream(cfg.file, fmRead, 1)
  var line = ""

  var titles: seq[string] = @[]
  var urls: seq[string] = @[]

  var url = string.none

  if not isNil(strm):
    while strm.readLine(line):
      if line.startsWith("** "):
        titles.insert(prepareLine(line), 0)
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

proc main*(cfg: Config): string =
  let (titles, urls) = readHeadlineItems(cfg)

  let rofiInput = titles.join("\n")

  # Write output to file, to prevent argument overflow in sub-shell when piping to rofi
  writeFile(cacheFile, rofiInput)

  let index = sh(&"cat {cacheFile} | rofi -i -levenshtein-sort -dmenu -p \"Run\" -format i -markup-rows")

  index
    .map((x) => x.replace("\n", ""))
    .map(parseInt)
    .map((x) => urls[x])
    .map((x) => x.replace("\"", "\\\""))
    .tap((x: string) => execShellCmd(&"xdg-open {x}"))
    .fold(e => e, v => $v)
