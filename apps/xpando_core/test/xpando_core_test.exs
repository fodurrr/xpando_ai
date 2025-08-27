defmodule XpandoCoreTest do
  use ExUnit.Case
  doctest XpandoCore

  test "greets the world" do
    assert XpandoCore.hello() == :world
  end
end
