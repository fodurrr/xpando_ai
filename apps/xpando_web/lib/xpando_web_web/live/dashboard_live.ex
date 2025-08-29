defmodule XpandoWebWeb.DashboardLive do
  @moduledoc """
  LiveView dashboard for XPando network monitoring and visualization.

  Provides real-time network topology display, node status monitoring,
  and interactive network graph visualization using DaisyUI components.
  """

  use XpandoWebWeb, :live_view

  alias XPando.Core.Node
  alias Phoenix.PubSub

  alias XpandoWebWeb.Components.UI.{
    NodeCard,
    NetworkStats,
    ThemeSwitcher,
    NetworkGraph,
    NodeDetail
  }

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to real-time network updates
    if connected?(socket) do
      PubSub.subscribe(XpandoWeb.PubSub, "network:updates")
      PubSub.subscribe(XpandoWeb.PubSub, "network:topology")
      PubSub.subscribe(XpandoWeb.PubSub, "cluster:events")
      PubSub.subscribe(XpandoWeb.PubSub, "node:heartbeat")

      # Set up periodic refresh for real-time updates
      :timer.send_interval(10_000, self(), :refresh_dashboard)
    end

    # Load initial network data
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:page_title, "xPando Network Dashboard")
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))
      |> assign(:loading, false)
      |> assign(:current_theme, "synthwave")
      |> assign(:selected_node, nil)
      |> assign(:graph_zoom, 1.0)
      |> assign(:show_node_detail, false)
      |> assign(:detail_node, nil)

    {:ok, socket}
  end

  @impl true
  def handle_info({:network_update, _update}, socket) do
    # Handle real-time network updates
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:node_heartbeat, node_id, status}, socket) do
    # Update individual node status
    updated_nodes =
      Enum.map(socket.assigns.nodes, fn node ->
        if to_string(node.id) == to_string(node_id) do
          Map.merge(node, %{
            status: status,
            last_heartbeat: DateTime.utc_now()
          })
        else
          node
        end
      end)

    socket =
      socket
      |> assign(:nodes, updated_nodes)
      |> assign(:network_stats, calculate_network_stats(updated_nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:node_join_request, node_id, _metadata}, socket) do
    # Handle node joining the network
    socket =
      socket
      |> push_event("show_toast", %{
        type: "info",
        message: "Node #{node_id} is joining the network"
      })

    # Refresh network data
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:node_leave, node_id, reason}, socket) do
    # Handle node leaving the network
    socket =
      socket
      |> push_event("show_toast", %{
        type: "warning",
        message: "Node #{node_id} left the network (#{reason})"
      })

    # Refresh network data
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:heartbeat, node_id, timestamp}, socket) do
    # Update node last heartbeat time
    updated_nodes =
      Enum.map(socket.assigns.nodes, fn node ->
        if to_string(node.id) == to_string(node_id) do
          Map.put(node, :last_heartbeat, timestamp)
        else
          node
        end
      end)

    socket =
      socket
      |> assign(:nodes, updated_nodes)
      |> assign(:network_stats, calculate_network_stats(updated_nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:network_topology_update, _topology}, socket) do
    # Handle topology updates
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    # Periodic dashboard refresh
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:close_node_detail}, socket) do
    socket =
      socket
      |> assign(:show_node_detail, false)
      |> assign(:detail_node, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:toast, type, message}, socket) do
    {:noreply, push_event(socket, "show_toast", %{type: type, message: message})}
  end

  @impl true
  def handle_info({:health_check, health_data}, socket) do
    # Handle health check updates - could be used to update network health stats
    require Logger
    Logger.debug("Received health check: #{inspect(health_data)}")

    # Optionally update network stats based on health check data
    updated_stats =
      if Map.has_key?(health_data, :total_nodes) and Map.has_key?(health_data, :healthy_count) do
        %{
          total_nodes: health_data.total_nodes,
          online_nodes: health_data.healthy_count,
          health_percentage:
            calculate_health_percentage(health_data.total_nodes, health_data.healthy_count)
        }
      else
        socket.assigns.network_stats
      end

    socket = assign(socket, :network_stats, updated_stats)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:error, error}, socket) do
    require Logger
    Logger.error("Dashboard LiveView error: #{inspect(error)}")

    socket =
      socket
      |> push_event("show_toast", %{
        type: "error",
        message: "An error occurred. Please refresh the page."
      })
      |> assign(:loading, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:topology_snapshot, _snapshot}, socket) do
    # Handle topology snapshots from the P2P network
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:heartbeat, _node}, socket) do
    # Handle heartbeat messages from P2P nodes
    # Refresh network data on heartbeat
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))

    {:noreply, socket}
  end

  # Catch-all for any unhandled messages to prevent crashes
  @impl true
  def handle_info(msg, socket) do
    require Logger
    Logger.debug("Unhandled message in DashboardLive: #{inspect(msg)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_network", _params, socket) do
    nodes = load_network_nodes()

    socket =
      socket
      |> assign(:nodes, nodes)
      |> assign(:network_stats, calculate_network_stats(nodes))
      |> push_event("show_toast", %{type: "info", message: "Network data refreshed"})

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_theme", %{"theme" => theme}, socket) do
    theme_name =
      case theme do
        "synthwave" -> "dark mode"
        "synthwave-light" -> "light mode"
        _ -> theme
      end

    socket =
      socket
      |> assign(:current_theme, theme)
      |> push_event("show_toast", %{type: "info", message: "Theme switched to #{theme_name}"})
      |> push_event("theme_changed", %{theme: theme})

    {:noreply, socket}
  end

  @impl true
  def handle_event("sync_theme", %{"theme" => theme}, socket) do
    socket = assign(socket, :current_theme, theme)
    {:noreply, socket}
  end

  @impl true
  def handle_event("view_node_details", %{"id" => node_id}, socket) do
    detail_node = Enum.find(socket.assigns.nodes, &(to_string(&1.id) == node_id))

    socket =
      socket
      |> assign(:show_node_detail, true)
      |> assign(:detail_node, detail_node)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_node", %{"id" => node_id}, socket) do
    selected_node = Enum.find(socket.assigns.nodes, &(to_string(&1.id) == node_id))

    socket =
      socket
      |> assign(:selected_node, selected_node)
      |> push_event("show_toast", %{type: "info", message: "Selected node: #{selected_node.name}"})

    {:noreply, socket}
  end

  @impl true
  def handle_event("zoom_in", _params, socket) do
    new_zoom = min(socket.assigns.graph_zoom * 1.2, 3.0)

    socket =
      socket
      |> assign(:graph_zoom, new_zoom)

    {:noreply, socket}
  end

  @impl true
  def handle_event("zoom_out", _params, socket) do
    new_zoom = max(socket.assigns.graph_zoom / 1.2, 0.5)

    socket =
      socket
      |> assign(:graph_zoom, new_zoom)

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_view", _params, socket) do
    socket =
      socket
      |> assign(:graph_zoom, 1.0)
      |> assign(:selected_node, nil)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="min-h-screen bg-base-100"
      data-theme={@current_theme}
      phx-hook="Theme"
      id="dashboard-root"
    >
      <!-- Toast Container -->
      <div id="toast-container" class="toast toast-end z-[60]" style="top: 5rem;" phx-hook="Toast">
      </div>
      
    <!-- Top Navigation similar to home page -->
      <nav
        class="navbar bg-base-300 shadow-lg sticky top-0 z-50 px-4"
        role="navigation"
        aria-label="main navigation"
      >
        <div class="navbar-start">
          <div class="dropdown">
            <button
              tabindex="0"
              class="btn btn-ghost lg:hidden"
              aria-label="Open mobile menu"
              aria-expanded="false"
              aria-controls="mobile-menu"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                aria-hidden="true"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h8m-8 6h16"
                />
              </svg>
            </button>
            <ul
              id="mobile-menu"
              tabindex="0"
              class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
              role="menu"
            >
              <li role="menuitem"><.link navigate={~p"/"} class="hover:text-primary">Home</.link></li>
            </ul>
          </div>
          <.link
            navigate={~p"/"}
            class="btn btn-ghost text-xl font-bold text-primary hover:text-primary-focus"
          >
            xPando AI
          </.link>
        </div>
        <div class="navbar-center hidden lg:flex">
          <ul class="menu menu-horizontal px-1" role="menubar">
            <li role="menuitem">
              <.link navigate={~p"/"} class="text-base-content hover:text-primary transition-colors">
                Home
              </.link>
            </li>
          </ul>
        </div>
        <div class="navbar-end">
          <ThemeSwitcher.theme_switcher
            current_theme={@current_theme}
            class="mr-2"
          />
          <.link navigate={~p"/app"} class="btn btn-secondary hover:btn-secondary-focus mr-2">
            <span class="hidden sm:inline">App</span>
            <span class="sm:hidden">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                />
              </svg>
            </span>
          </.link>
          <button
            class="btn btn-primary hover:btn-primary-focus"
            phx-click="refresh_network"
            disabled={@loading}
            aria-label="Refresh network data"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4 mr-2"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            <span class="hidden sm:inline">Refresh</span>
          </button>
        </div>
      </nav>
      
    <!-- Main Dashboard Content -->
      <section class="py-8 bg-base-200 min-h-screen">
        <div class="container mx-auto px-2 sm:px-4 py-4 sm:py-8">
          <!-- Network Statistics using new component -->
          <div phx-hook="Metrics" id="network-metrics">
            <NetworkStats.network_stats stats={@network_stats} class="mb-4 sm:mb-8" layout="vertical" />
          </div>
          
    <!-- Network Visualization Grid -->
          <div class="dashboard-grid grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6">
            <!-- Interactive Network Graph -->
            <div class="lg:col-span-2 order-2 lg:order-1">
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body p-2 sm:p-4">
                  <h2 class="card-title mb-2 sm:mb-4 text-lg sm:text-xl">Network Topology</h2>
                  <%= if Enum.empty?(@nodes) do %>
                    <div class="h-64 sm:h-96 bg-base-200 rounded-lg flex items-center justify-center">
                      <div class="text-center text-base-content px-4">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-12 sm:h-16 w-12 sm:w-16 mb-2 sm:mb-4 opacity-50 mx-auto"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 10V3L4 14h7v7l9-11h-7z"
                          />
                        </svg>
                        <p class="text-base sm:text-lg font-medium">No Network Nodes</p>
                        <p class="text-xs sm:text-sm opacity-70">Add nodes to see network topology</p>
                      </div>
                    </div>
                  <% else %>
                    <div
                      phx-hook="NetworkGraph"
                      id="network-graph-container"
                      class="network-graph-container"
                    >
                      <NetworkGraph.network_graph
                        nodes={@nodes}
                        width={600}
                        height={350}
                        class="border border-base-300 rounded-lg w-full"
                      />
                    </div>
                  <% end %>
                  
    <!-- Selected Node Info Panel -->
                  <%= if @selected_node do %>
                    <div class="mt-4 p-3 bg-base-200 rounded-lg">
                      <h3 class="font-medium text-sm mb-2">Selected Node</h3>
                      <div class="grid grid-cols-2 gap-4 text-sm">
                        <div>
                          <span class="font-medium">Name:</span> {@selected_node.name}
                        </div>
                        <div>
                          <span class="font-medium">Status:</span>
                          <span class={[
                            "badge badge-xs ml-1",
                            @selected_node.status == :online && "badge-success",
                            @selected_node.status == :offline && "badge-error",
                            @selected_node.status == :syncing && "badge-warning"
                          ]}>
                            {@selected_node.status}
                          </span>
                        </div>
                        <%= if @selected_node.specializations not in [nil, []] do %>
                          <div class="col-span-2">
                            <span class="font-medium">Specializations:</span>
                            <div class="flex flex-wrap gap-1 mt-1">
                              <%= for spec <- @selected_node.specializations do %>
                                <span class="badge badge-outline badge-xs">{spec}</span>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
            
    <!-- Nodes List using NodeCard components -->
            <div class="lg:col-span-1 order-1 lg:order-2">
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body p-2 sm:p-4">
                  <h2 class="card-title text-lg sm:text-xl">Active Nodes</h2>
                  <div
                    class="space-y-2 sm:space-y-3 max-h-64 sm:max-h-96 overflow-y-auto mobile-scroll"
                    phx-hook="NetworkStatus"
                    id="nodes-list"
                  >
                    <%= if Enum.empty?(@nodes) do %>
                      <div class="alert alert-info">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="stroke-current shrink-0 h-6 w-6"
                          fill="none"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                          />
                        </svg>
                        <span>No nodes found. Network is initializing...</span>
                      </div>
                    <% else %>
                      <%= for node <- @nodes do %>
                        <NodeCard.node_card node={node} class="card-compact">
                          <:actions :let={node}>
                            <button
                              class="btn btn-xs btn-outline"
                              phx-click="view_node_details"
                              phx-value-id={node.id}
                            >
                              View
                            </button>
                          </:actions>
                        </NodeCard.node_card>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Node Detail Modal -->
      <%= if @show_node_detail && @detail_node do %>
        <.live_component module={NodeDetail} id="node-detail-modal" node={@detail_node} />
      <% end %>
    </div>
    """
  end

  # Private functions

  defp load_network_nodes do
    # Using Ash to load node data with proper error logging
    case Ash.read(Node, domain: XPando.Core) do
      {:ok, nodes} ->
        nodes

      {:error, error} ->
        require Logger
        Logger.warning("Failed to load network nodes: #{inspect(error)}")
        []
    end
  end

  defp calculate_network_stats(nodes) do
    total = length(nodes)
    online = Enum.count(nodes, &(&1.status == :online))

    health_percentage =
      if total > 0 do
        round(online / total * 100)
      else
        0
      end

    %{
      total_nodes: total,
      online_nodes: online,
      health_percentage: health_percentage
    }
  end

  defp calculate_health_percentage(total, healthy) when total > 0 do
    round(healthy / total * 100)
  end

  defp calculate_health_percentage(_, _), do: 0
end
