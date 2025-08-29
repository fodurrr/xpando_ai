defmodule XPando.Core do
  @moduledoc """
  Core Ash Domain for the xPando distributed AI knowledge network.

  Defines the main domain containing Node, Knowledge, and Contribution resources
  for managing P2P network participants and their knowledge contributions.

  ## Examples

  List all resources in the domain:

      iex> # Core domain resources
      iex> resources = [
      ...>   XPando.Core.Node,
      ...>   XPando.Core.Knowledge, 
      ...>   XPando.Core.Contribution,
      ...>   XPando.Core.Token,
      ...>   XPando.Core.User,
      ...>   XPando.Core.Newsletter
      ...> ]
      iex> length(resources)
      6

  Domain operation examples:

      iex> # Standard domain operations available
      iex> operations = [:create, :read, :update, :destroy]
      iex> :read in operations
      true

  Resource relationships:

      iex> # Key relationships in the domain
      iex> relationships = %{
      ...>   "nodes_contribute_to" => "knowledge",
      ...>   "contributions_track" => "quality_and_rewards", 
      ...>   "users_operate" => "nodes",
      ...>   "tokens_secure" => "authentication"
      ...> }
      iex> Map.has_key?(relationships, "nodes_contribute_to")
      true

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
