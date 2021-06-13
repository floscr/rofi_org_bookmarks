import ../src/lib/main
import fp/option
import sugar
import unittest

suite "Helper functions":

  test "parseTags":
    check: parseTags("** My item :FOO:BAR:BAZ:") == ("** My item", ":FOO:BAR:BAZ:".some)
    check: parseTags("** My item") == ("** My item", string.none)
