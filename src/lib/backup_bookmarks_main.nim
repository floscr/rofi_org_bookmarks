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
  EnvPaths* {.requiresInit.} = ref object
    emacs*: string
    emacsInitFilePath*: string
    linguist*: string
    readable*: string
  Env* {.requiresInit.} = ref object
    paths*: EnvPaths
  DocKind = enum
    orgDoc
    htmlDoc
  Doc {.requiresInit.} = ref object
    content: string
    kind: DocKind

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

const READABLE_BIN_PATH {.strdefine.} = ""
let readableBinPath* = READABLE_BIN_PATH
.strDefineToMaybe()
.getOrElse("readable")

const EMACS_INIT_FILE_PATH {.strdefine.} = ""
let emacsInitFilePath* = EMACS_INIT_FILE_PATH
.strDefineToMaybe()
.map(x => x.joinPath("/lib.el"))

let defaultEnv = Env(
  paths: EnvPaths(
    emacs: emacsBinPath,
    emacsInitFilePath: emacsInitFilePath.getOrElse(""),
    linguist: linguistBinPath,
    readable: readableBinPath,
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


proc backupBookmark*(url: string, scraper: string, env = defaultEnv): Either[string, Doc] =
  case scraper:
    of "readable":
      sh(&"""{env.paths.readable} "{url}" --quiet""")
      .map(content => Doc(
        kind: htmlDoc,
        content: content,
      ))
    else:
      sh(&"""{env.paths.emacs} --batch -l {env.paths.emacsInitFilePath} --eval '(rofi-org-bookmarks/runn "{url}")'""")
      .map(content => Doc(
        kind: orgDoc,
        content: cleanupOrg(content),
      ))

proc convertDocs(
  docs: seq[Doc],
  dstPath: string,
  title: Option[string],
): Either[string, string] =
  let title = title
  .convertMaybe()
  .orElse(dstPath.splitFile[1].just())
  .map(x => &" --metadata title=\"{x}\"")
  .getOrElse("")

  docs
  .map((x: Doc) => (
    let extension =
      case x.kind:
        of orgDoc: "org"
        of htmlDoc: "html"

    let (cfile, path) = createTempFile("backup_bookmarks_file_", &"_end.{extension}")
    cfile.write(x.content)
    cfile.setFilePos(0)
    cfile.close()
    path
  ))
  .join(" ")
  .right(string)
  .flatMap((paths: string) => sh(&"""pandoc {paths} -o {dstPath}{title}"""))

proc backupBookmarks*(
  urls: seq[string],
  output = none(string),
  title = none(string),
  scraper = "emacs",
  env = defaultEnv
): string =
  (@errors, @docs) := urls
  .asList()
  .foldLeft(
    (newSeq[string](), newSeq[Doc]()),
    (acc, cur) => backupBookmark(url = cur, scraper = scraper, env = env)
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
    of ([all @docs], Some(@dstPath), _):
      convertDocs(
        docs = docs,
        dstPath = dstPath,
        title = title,
      )
      .map(xs => &"Saved output to {dstPath}\n\n{xs}")
    of ([all @docs], None(), _):
      docs
      .foldl(a & "\n" & b.content, "")
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
      readable: readableBinPath,
    )
  )
  echo backupBookmarks(
    urls = @["https://xi-editor.io/docs/frontend-notes.html"],
    env = env,
    output = "/tmp/foo.epub".some,
    scraper = "readable",
  )
