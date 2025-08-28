# Testing Strategy

## Testing Pyramid
```
          E2E Tests (5%)
         /              \
    Integration Tests (25%)
       /                  \
  Unit Tests (70%)    Property Tests
```

## Test Organization

### Frontend Tests
```
apps/xpando_web/test/
├── xpando_web/
│   ├── live/
│   │   ├── dashboard_live_test.exs
│   │   └── nodes_live_test.exs
│   └── components/
│       └── node_card_test.exs
├── support/
│   ├── conn_case.ex
│   └── fixtures/
└── test_helper.exs
```

### Backend Tests
```
apps/xpando_core/test/
├── xpando/
│   ├── core/
│   │   ├── node_test.exs
│   │   └── knowledge_test.exs
│   ├── mother_core/
│   │   └── consensus_test.exs
│   └── ai/
│       └── adapters_test.exs
├── support/
│   └── data_case.ex
└── test_helper.exs
```

### E2E Tests
```
test/e2e/
├── flows/
│   ├── node_registration_test.exs
│   └── knowledge_submission_test.exs
└── support/
    └── wallaby_case.ex
```

## Test Examples

### Frontend Component Test
```elixir
defmodule XPandoWeb.NodeCardTest do
  use XPandoWeb.ConnCase
  import Phoenix.LiveViewTest
  
  test "renders node information", %{conn: conn} do
    node = node_fixture(%{name: "Test Node", status: :online})
    
    {:ok, _view, html} = live(conn, "/nodes/#{node.id}")
    
    assert html =~ "Test Node"
    assert html =~ "online"
    assert html =~ "Reputation"
  end
end
```

### Backend API Test
```elixir
defmodule XPando.Core.NodeTest do
  use XPando.DataCase
  
  describe "register/1" do
    test "creates a node with valid params" do
      params = %{
        name: "Expert Node",
        specializations: ["nlp", "vision"],
        wallet_address: "7xKXtg..."
      }
      
      assert {:ok, node} = XPando.Core.Node.register(params)
      assert node.name == "Expert Node"
      assert "nlp" in node.specializations
    end
    
    test "validates required fields" do
      assert {:error, changeset} = XPando.Core.Node.register(%{})
      assert "can't be blank" in errors_on(changeset).name
    end
  end
end
```

### E2E Test
```elixir
defmodule XPando.E2E.NodeRegistrationTest do
  use XPando.WallabyCase
  
  feature "node can register and join network", %{session: session} do
    session
    |> visit("/")
    |> click(Query.link("Register Node"))
    |> fill_in(Query.text_field("Name"), with: "New Node")
    |> fill_in(Query.text_field("Specializations"), with: "nlp,vision")
    |> click(Query.button("Register"))
    |> assert_has(Query.text("Registration successful"))
    |> assert_has(Query.text("New Node"))
  end
end
```