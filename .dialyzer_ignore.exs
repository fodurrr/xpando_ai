[
  # ExUnit.Callbacks functions that don't exist in PLT - these are generated at compile time
  ~r"Function ExUnit\.Callbacks\.__merge__/4 does not exist\.",
  ~r"Function ExUnit\.Callbacks\.__noop__/0 does not exist\.",
  ~r"Function ExUnit\.CaseTemplate\.__proxy__/2 does not exist\.",
  ~r"Function ExUnit\.Callbacks\.on_exit/1 does not exist\.",

  # Test support files using these functions
  ~r"test/support/conn_case\.ex.*unknown_function",
  ~r"test/support/data_case\.ex.*unknown_function"
]
