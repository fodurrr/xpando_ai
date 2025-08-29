defmodule XPando.Core.DoctestsTest do
  @moduledoc """
  Runs all module doctests to ensure documentation examples remain current.

  Doctests live in the source modules but need to be explicitly tested.
  This file ensures they run as part of the test suite.
  """
  use ExUnit.Case, async: true

  # Core Resources
  doctest XPando.Core.User
  doctest XPando.Core.Node
  doctest XPando.Core.Knowledge
  doctest XPando.Core.Contribution
  doctest XPando.Core.Token

  # Domain
  doctest XPando.Core

  # Validators
  doctest XPando.Core.Node.ValidatePublicKey
  doctest XPando.Core.Knowledge.ValidateContentHash
  doctest XPando.Core.Contribution.ValidateContributionData
  doctest XPando.Core.Node.ValidateNodeIdentity
end
