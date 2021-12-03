import std/os
import std/osproc
import std/sugar
import std/strformat
import std/strutils
import fp/either
import fp/maybe
import colorize

proc sh*(cmd: string, opts = {poStdErrToStdOut}): Either[string, string] =
  ## Execute a shell command and wrap it in an Either
  ## Right for a successful command (exit code: 0)
  ## Left for a failing command (any other exit code, so 1)
  let (res, exitCode) = execCmdEx(cmd, opts)
  if exitCode == 0:
    return res
        .strip
        .right(string)
  return res
    .strip
    .left(string)

proc strDefineToMaybe(x: string): Maybe[string] =
  x.just()
  .notEmpty()
  .filter(x => not x.defined())

const EMACS_BIN_PATH {.strdefine.} = ""
let emacsBinPath* = EMACS_BIN_PATH
.strDefineToMaybe()
.getOrElse("emacs")

const EMACS_INIT_FILE_PATH {.strdefine.} = ""
let emacsInitFilePath* = EMACS_INIT_FILE_PATH
.strDefineToMaybe()
.map(x => x.joinPath("/lib.el"))


proc errorMsg(err: string, errType = "Error"): string =
  &"""[{errType.fgRed()}]:
{err}
"""

proc backupBookmark*(url: string): string =
  sh(&"""{emacsBinPath} --batch -l {emacsInitFilePath.get()} --eval '(rofi-org-bookmarks/runn "{url}")'""")
  .fold(
    err => err.errorMsg(),
    x => x,
  )
