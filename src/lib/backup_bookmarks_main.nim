import std/os
import std/osproc
import std/sugar
import std/strformat
import std/tempfiles
import std/strutils
import std/collections/sequtils
import std/options
import fp/either
import fp/maybe
import fp/list
import colorize
import tempfile
import fusion/matching
import ./utils

{.experimental: "caseStmtMacros".}

type
  EnvPaths* = ref object {.requiresInit.}
    emacs*: string
    emacsInitFilePath*: string
    linguist*: string
  Env* = ref object {.requiresInit.}
    paths*: EnvPaths

proc `$`*(x: EnvPaths): string =
  &"""EnvPaths(
  emacs: {x.emacs},
  emacsInitFilePath: {x.emacsInitFilePath},
  linguist: {x.linguist},
)"""

proc `$`*(x: Env): string =
  &"""Env(
  paths: {x.paths}
)"""

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

let defaultEnv = Env(
  paths: EnvPaths(
    emacs: emacsBinPath,
    emacsInitFilePath: emacsInitFilePath.getOrElse(""),
    linguist: linguistBinPath,
  ),
)

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


proc backupBookmark*(url: string, env = defaultEnv): Either[string, string] =
  sh(&"""{env.paths.emacs} --batch -l {env.paths.emacsInitFilePath} --eval '(rofi-org-bookmarks/runn "{url}")'""")
  .map(cleanupOrg)

proc convertDocs(srcPaths: seq[string], dstPath: string): Either[string, string] =
  srcPaths
  .map((x: string) => (
    let (cfile, path) = createTempFile("backup_bookmarks_file_", "_end.org")
    cfile.write(x)
    cfile.setFilePos(0)
    cfile.close()
    path
  ))
  .join(" ")
  .right(string)
  .flatMap((paths: string) => sh(&"""pandoc {paths} -o {dstPath}"""))

proc backupBookmarks*(urls: seq[string], output = none(string), env = defaultEnv): string =
  (@errors, @docs) := urls
  .asList()
  .foldLeft(
    (newSeq[string](), newSeq[string]()),
    (acc, cur) => backupBookmark(cur, env = env)
    .fold(
      err => (acc[0] & err, acc[1]),
      docs => (acc[0], acc[1] & docs),
    )
  )

  let output = case (docs, output, errors):
    # No docs have been converted
    of ([], _, [all @errs]):
      errs
      .foldl(a & "\n" & b, "Errors found: \n")
      .left(string)
    # Export docs to a file
    of ([all @srcPaths], Some(@dstPath), _):
      convertDocs(srcPaths = srcPaths, dstPath = dstPath)
      # .map(_ => &"Saved output to {dstPath}")
    of ([all @docs], None(), _):
      docs
      .foldl(a & "\n" & b, "")
      .right(string)
    else:
      "".left(string)

  output.fold(
    err => $err,
    msg => msg,
  )

when isMainModule:
  let env = Env(
    paths: EnvPaths(
      emacs: emacsBinPath,
      emacsInitFilePath: currentSourcePath().splitFile()[0].joinPath("../rofi_org_bookmarks_backup.el"),
      linguist: linguistBinPath,
    )
  )
  echo backupBookmarks(urls = @[
    "https://xi-editor.io/docs/frontend-notes.html" "https://xi-editor.io/docs/frontend-protocol.html" "https://xi-editor.io/docs/plugin.html" "https://xi-editor.io/docs/config.html" "https://xi-editor.io/docs/crdt.html" "https://xi-editor.io/docs/crdt-details.html" "https://xi-editor.io/docs/fuchsia-ledger-crdts.html" "https://xi-editor.io/docs/rope_science_00.html" "https://xi-editor.io/docs/rope_science_01.html" "https://xi-editor.io/docs/rope_science_02.html" "https://xi-editor.io/docs/rope_science_03.html" "https://xi-editor.io/docs/rope_science_04.html" "https://xi-editor.io/docs/rope_science_05.html" "https://xi-editor.io/docs/rope_science_06.html" "https://xi-editor.io/docs/rope_science_08.html" "https://xi-editor.io/docs/rope_science_08a.html" "https://xi-editor.io/docs/rope_science_09.html" "https://xi-editor.io/docs/rope_science_10.html" "https://xi-editor.io/docs/rope_science_11.html" "https://xi-editor.io/docs/rope_science_12.html"
  ], env = env, output = "/tmp/foo.epub".some)
