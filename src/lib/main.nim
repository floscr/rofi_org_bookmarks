import utils
import fp/option
import fp/either
import sugar
import strformat
import tempfile
import os

proc main*(): any =
  let file = readFile("/home/floscr/Documents/Org/Bookmarks/bookmarks.org")
  echo file
