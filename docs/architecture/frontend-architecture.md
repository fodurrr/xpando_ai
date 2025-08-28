# Frontend Architecture

## Component Architecture

### Component Organization
```
apps/xpando_web/lib/xpando_web/
├── components/
│   ├── core_components.ex       # Shared Phoenix components
│   ├── layouts/
│   │   ├── app.html.heex       # Main app layout
│   │   └── root.html.heex      # Root document layout
│   └── ui/
│       ├── node_card.ex        # Node display component
│       ├── knowledge_graph.ex  # Knowledge visualization
│       └── contribution_list.ex # Contribution tracking
├── live/
│   ├── dashboard_live/
│   │   ├── index.ex            # Main dashboard
│   │   └── components/
│   │       ├── network_stats.ex
│   │       └── inference_panel.ex
│   ├── nodes_live/
│   │   ├── index.ex            # Node listing
│   │   ├── show.ex             # Node details
│   │   └── form.ex             # Node registration
│   └── knowledge_live/
│       ├── index.ex            # Knowledge browser
│       └── explorer.ex         # Interactive explorer
└── controllers/
    └── api/
        └── health_controller.ex # Health check endpoint
```

### Component Template (Phoenix LiveView Component)
```elixir
defmodule XPandoWeb.Components.NodeCard do
  use XPandoWeb, :live_component
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">
          <%= @node.name %>
          <div class="badge badge-secondary"><%= @node.status %></div>
        </h2>
        <p>Reputation: <%= @node.reputation_score %></p>
        <div class="card-actions justify-end">
          <.link patch={~p"/nodes/#{@node.id}"} class="btn btn-primary">
            View Details
          </.link>
        </div>
      </div>
    </div>
    """
  end
  
  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_node_metrics()}
  end
end
```

## State Management Architecture

### LiveView State Structure
```elixir
defmodule XPandoWeb.DashboardLive do
  use XPandoWeb, :live_view
  
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time updates
      Phoenix.PubSub.subscribe(XPando.PubSub, "network:updates")
      :timer.send_interval(5000, self(), :refresh_stats)
    end
    
    {:ok,
     socket
     |> assign(:nodes, list_online_nodes())
     |> assign(:network_stats, get_network_stats())
     |> assign(:recent_knowledge, list_recent_knowledge())}
  end
  
  @impl true
  def handle_info({:network_update, payload}, socket) do
    {:noreply, update_network_state(socket, payload)}
  end
end
```

### State Management Patterns
- Server-side state management via LiveView assigns
- Real-time updates through Phoenix PubSub
- Optimistic UI updates with server confirmation
- Session state in ETS for performance

## Routing Architecture

### Route Organization
```elixir
# lib/xpando_web/router.ex
defmodule XPandoWeb.Router do
  use XPandoWeb, :router
  use AshAuthentication.Phoenix.Router
  
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {XPandoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end
  
  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end
  
  scope "/", XPandoWeb do
    pipe_through :browser
    
    live "/", DashboardLive.Index, :index
    
    live "/nodes", NodesLive.Index, :index
    live "/nodes/new", NodesLive.Form, :new
    live "/nodes/:id", NodesLive.Show, :show
    
    live "/knowledge", KnowledgeLive.Index, :index
    live "/knowledge/explorer", KnowledgeLive.Explorer, :explorer
    
    # Authentication routes
    auth_routes AuthController, XPando.Accounts.User, path: "/auth"
  end
  
  scope "/api", XPandoWeb do
    pipe_through :api
    
    forward "/graphql", Absinthe.Plug, schema: XPandoWeb.Schema
  end
  
  # Admin routes
  scope "/admin" do
    pipe_through [:browser, :require_authenticated_user, :require_admin]
    
    ash_admin "/dashboard"
  end
end
```

### Protected Route Pattern
```elixir
defmodule XPandoWeb.Live.Helpers do
  import Phoenix.LiveView
  
  def on_mount(:require_authenticated_user, _params, session, socket) do
    case session["user_token"] do
      nil ->
        {:halt, redirect(socket, to: "/auth/sign_in")}
      
      token ->
        case XPando.Accounts.get_user_by_session_token(token) do
          nil -> {:halt, redirect(socket, to: "/auth/sign_in")}
          user -> {:cont, assign(socket, :current_user, user)}
        end
    end
  end
end
```

## Frontend Services Layer

### API Client Setup (GraphQL via Absinthe Client)
```elixir
defmodule XPandoWeb.GraphQL.Client do
  @moduledoc """
  GraphQL client for frontend LiveView components
  """
  
  alias XPandoWeb.Schema
  
  def query(document, variables \\ %{}) do
    Absinthe.run(document, Schema, variables: variables)
  end
  
  def subscribe(subscription, variables \\ %{}) do
    Absinthe.run(subscription, Schema,
      variables: variables,
      context: %{pubsub: XPando.PubSub}
    )
  end
end
```

### Service Example (Node Service)
```elixir
defmodule XPandoWeb.Services.NodeService do
  @moduledoc """
  Service layer for node operations
  """
  
  import XPandoWeb.GraphQL.Client
  alias XPando.Core.Node
  
  def list_nodes(opts \\ []) do
    query = """
    query ListNodes($first: Int, $after: String) {
      nodes(first: $first, after: $after) {
        edges {
          node {
            id
            name
            status
            reputationScore
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
    """
    
    case query(query, Enum.into(opts, %{})) do
      {:ok, %{data: %{"nodes" => nodes}}} -> {:ok, nodes}
      error -> error
    end
  end
  
  def register_node(params) do
    Node
    |> Ash.Changeset.for_create(:register, params)
    |> Ash.create()
  end
end
```