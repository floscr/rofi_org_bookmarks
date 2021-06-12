import cligen
import lib/main

{.experimental.}

proc cli(): int =
  discard main()
  1

dispatch(cli, help = {})
