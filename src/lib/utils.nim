import osproc
import strutils
import osproc
import fp/option
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

## Option

proc bitap*[T](xs: Option[T], errFn: () -> void, succFn: T -> void): Option[T] =
  if (xs.isDefined):
    succFn(xs.get)
  else:
    errFn()
  xs

## Either

proc tap*[E,A,B](e: Either[E,A], f: A -> B): Either[E,A] =
  if e.isRight: discard f(e.get)
  e

proc log*[E,A](e: Either[E,A]): Either[E,A] =
  echo $e
  e
