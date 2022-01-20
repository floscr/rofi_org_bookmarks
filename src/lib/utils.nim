import osproc
import strutils
import osproc
import fp/maybe
import fp/either
import sugar

proc sh*(cmd: string, workingDir = ""): Either[string, string] =
  let (res, exitCode) = execCmdEx(cmd, workingDir=workingDir)
  if exitCode == 0:
    return res
      .strip
      .right(string)
  return res
    .strip
    .left(string)

proc strDefineToMaybe*(x: string): Maybe[string] =
  x.just()
  .notEmpty()
  .filter(x => not x.defined())
