import fp/option

{.experimental.}

type CLIArgs* = ref object
  input*: Option[string]
  output*: Option[string]
