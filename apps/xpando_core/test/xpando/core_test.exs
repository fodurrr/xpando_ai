defmodule XPando.CoreTest do
  @moduledoc """
  Tests for the Core domain module.
  """
  use XPando.DataCase

  alias Ash.Domain.Info

  describe "Core domain" do
    test "domain has all expected resources" do
      resources = XPando.Core |> Info.resources()
      resource_names = Enum.map(resources, &Atom.to_string/1)

      expected_resources = [
        "Elixir.XPando.Core.Node",
        "Elixir.XPando.Core.Knowledge",
        "Elixir.XPando.Core.Contribution",
        "Elixir.XPando.Core.Token",
        "Elixir.XPando.Core.User",
        "Elixir.XPando.Core.Newsletter"
      ]

      for expected <- expected_resources do
        assert expected in resource_names, "Expected resource #{expected} not found"
      end
    end

    test "can perform basic operations through domain" do
      # Test basic read operations through the domain
      nodes = Ash.read!(XPando.Core.Node, domain: XPando.Core, authorize?: false)
      assert is_list(nodes)

      knowledge = Ash.read!(XPando.Core.Knowledge, domain: XPando.Core, authorize?: false)
      assert is_list(knowledge)

      contributions = Ash.read!(XPando.Core.Contribution, domain: XPando.Core, authorize?: false)
      assert is_list(contributions)
    end
  end
end
