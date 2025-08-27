defmodule XPando.Core do
  use Ash.Domain

  resources do
    resource(XPando.Core.Node)
    resource(XPando.Core.Knowledge)
    resource(XPando.Core.Contribution)
  end
end
