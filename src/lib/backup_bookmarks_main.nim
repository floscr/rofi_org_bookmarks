import std/os
import std/osproc
import std/sugar
import std/strformat
import std/tempfiles
import std/strutils
import std/collections/sequtils
import fp/either
import fp/maybe
import colorize

const EMACS_BIN_PATH {.strdefine.} = ""
let emacsBinPath* = EMACS_BIN_PATH
.strDefineToMaybe()
.getOrElse("emacs")

const LINGUIST_BIN_PATH {.strdefine.} = ""
let linguistBinPath* = LINGUIST_BIN_PATH
.strDefineToMaybe()
.getOrElse("linguist")

const EMACS_INIT_FILE_PATH {.strdefine.} = ""
let emacsInitFilePath* = EMACS_INIT_FILE_PATH
.strDefineToMaybe()
.map(x => x.joinPath("/lib.el"))

proc errorMsg(err: string, errType = "Error"): string =
  &"""[{errType.fgRed()}]:
{err}
"""

proc cleanupOrg*(doc: string): string =
  var blocks: seq[string]
  var codeBlock: Maybe[seq[string]] = nothing(newSeq[string]())

  for line in splitLines(doc):

    if line.contains("#+begin_example") and codeBlock.isEmpty():
      codeBlock = just(newSeq[string]())

    elif line.contains("#+end_example") and codeBlock.isDefined():
      let xs: seq[string] = codeBlock
      .get()
      .map(x => x.dedent(count=4))

      let (cfile, path) = createTempFile("backup_bookmarks_file_", "_end.tmp")
      cfile.write(xs.join("\n"))
      cfile.setFilePos 0

      # let format = sh(&"{linguistBinPath} {path}")
      # echo path
      # echo format

      blocks = blocks.concat(xs)
      codeBlock = nothing(newSeq[string]())

    elif codeBlock.isDefined():
      codeBlock = codeBlock.map(xs => xs.concat(@[line.dedent(4)]))

    else:
      blocks.add(line)

  blocks.join("\n")


proc backupBookmark*(url: string): string =
  sh(&"""{emacsBinPath} --batch -l {emacsInitFilePath.get()} --eval '(rofi-org-bookmarks/runn "{url}")'""")
  .map(cleanupOrg)
  .fold(
    err => err.errorMsg(),
    x => x,
  )

when isMainModule:
  let content = """
**** The Code

  It uses [[https://github.com/joaotavora/yasnippet][yasnippet]] to insert the code block. [[https://github.com/joaotavora/yasnippet][Yasnippet]] can execute =emacs-lisp= code in it's own snippets, so here we call the function =(+yas/org-last-src-lang)= which finds the nearest src block, and takes it's language type ✨.

  #+begin_example
     # -*- mode: snippet -*-
    # name: #+begin_src
    # uuid: src
    # key: <
    # --
    \\#+begin_src ${1:`(+yas/org-last-src-lang)`}
    `%`$0
    \\#+end_src
  #+end_example

  You've got to remove the =\\= escaping characters in the code block above, until I figure out how to include escaping in source blocks with [[https://orga.js.org/][orga]] 🥲
"""

  discard cleanupOrg(content)
