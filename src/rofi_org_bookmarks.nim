import cligen
import lib/main

{.experimental.}

proc cli(): int =
  echo main()
  0

dispatch(cli, help = {})
