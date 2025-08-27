# Dialyzer ignore warnings file
[
  # ExUnit test support functions - ignore all ExUnit-related warnings
  ~r/test\/support\/.*\.ex.*ExUnit/,
  ~r/Function ExUnit\./,
  ~r/unknown_function.*test\/support/,

  # Specific ExUnit callback warnings
  ~r/Function ExUnit\.Callbacks\.__merge__\/4 does not exist/,
  ~r/Function ExUnit\.Callbacks\.__noop__\/0 does not exist/,
  ~r/Function ExUnit\.CaseTemplate\.__proxy__\/2 does not exist/,
  ~r/Function ExUnit\.Callbacks\.on_exit\/1 does not exist/,

  # xmerl warnings (standard library warnings we can't fix)
  ~r/xmerl_ucs\.erl.*missing specification/
]
