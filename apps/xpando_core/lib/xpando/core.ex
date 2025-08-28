defmodule XPando.Core do
  @moduledoc """
  Core Ash Domain for the xPando distributed AI knowledge network.

  Defines the main domain containing Node, Knowledge, and Contribution resources
  for managing P2P network participants and their knowledge contributions.
  """

  use Ash.Domain

  resources do
    resource(XPando.Core.Node)
    resource(XPando.Core.Knowledge)
    resource(XPando.Core.Contribution)
    resource(XPando.Core.Token)
    resource(XPando.Core.User)
    resource(XPando.Core.Newsletter)
  end
end
