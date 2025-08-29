defmodule XpandoWebWeb.Components.UI.NetworkGraph do
  @moduledoc """
  Interactive Network Graph component for visualizing P2P network topology.

  Uses SVG for scalable vector graphics with real-time updates.
  Follows Frontend Design Principles with accessibility and responsive design.
  """

  use Phoenix.Component

  # Layout configuration constants
  @default_layout_radius_factor 0.35
  @position_noise_range 20
  @random_connection_probability 0.3

  defp default_node_radius, do: 20
  defp default_outer_radius, do: 25

  attr :nodes, :list, required: true, doc: "List of network nodes"
  attr :width, :integer, default: 800, doc: "SVG canvas width"
  attr :height, :integer, default: 600, doc: "SVG canvas height"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :interactive, :boolean, default: true, doc: "Enable node interactions"

  def network_graph(assigns) do
    # Calculate node positions using a simple circular layout
    assigns =
      assign(
        assigns,
        :positioned_nodes,
        calculate_node_positions(assigns.nodes, assigns.width, assigns.height)
      )

    ~H"""
    <div
      class={["relative bg-base-200 rounded-lg overflow-hidden", @class]}
      role="img"
      aria-label="Network topology visualization"
    >
      
    <!-- SVG Network Graph -->
      <svg
        width={@width}
        height={@height}
        class="w-full h-full"
        viewBox={"0 0 #{@width} #{@height}"}
        xmlns="http://www.w3.org/2000/svg"
      >
        <!-- Background -->
        <rect width="100%" height="100%" fill="transparent" />
        
    <!-- Network Connections (drawn first, behind nodes) -->
        <%= for connection <- generate_connections(@positioned_nodes) do %>
          <line
            x1={connection.x1}
            y1={connection.y1}
            x2={connection.x2}
            y2={connection.y2}
            stroke="currentColor"
            stroke-width="2"
            stroke-opacity="0.3"
            class={[
              connection_status_class(connection.status),
              "transition-all duration-300"
            ]}
            role="presentation"
            aria-hidden="true"
          >
            <!-- Connection animation for active connections -->
            <%= if connection.status == :active do %>
              <animate
                attributeName="stroke-opacity"
                values="0.3;0.8;0.3"
                dur="2s"
                repeatCount="indefinite"
              />
            <% end %>
          </line>
        <% end %>
        
    <!-- Network Nodes -->
        <%= for node <- @positioned_nodes do %>
          <g class="node-group" role="group" aria-label={"Node #{node.name}"}>
            <!-- Node outer ring (status indicator) -->
            <circle
              cx={node.x}
              cy={node.y}
              r={default_outer_radius()}
              fill="none"
              stroke="currentColor"
              stroke-width="3"
              class={[
                node_status_ring_class(node.status),
                "transition-all duration-300"
              ]}
              opacity="0.6"
            >
              <!-- Pulse animation for online nodes -->
              <%= if node.status == :online do %>
                <animate
                  attributeName="r"
                  values="25;30;25"
                  dur="3s"
                  repeatCount="indefinite"
                />
                <animate
                  attributeName="opacity"
                  values="0.6;0.2;0.6"
                  dur="3s"
                  repeatCount="indefinite"
                />
              <% end %>
            </circle>
            
    <!-- Node main circle -->
            <circle
              cx={node.x}
              cy={node.y}
              r={default_node_radius()}
              fill="currentColor"
              class={[
                node_status_class(node.status),
                @interactive && "cursor-pointer hover:scale-110",
                "transition-all duration-300"
              ]}
              phx-click={@interactive && "select_node"}
              phx-value-id={node.id}
              role="button"
              tabindex="0"
              aria-label={"Select node #{node.name}, status: #{node.status}"}
              onkeydown="if(event.key === 'Enter' || event.key === ' ') this.click()"
            />
            
    <!-- Node icon/specialization indicator -->
            <g transform={"translate(#{node.x - 8}, #{node.y - 8})"}>
              {Phoenix.HTML.raw(node_icon_svg(node.specializations))}
            </g>
            
    <!-- Node label -->
            <text
              x={node.x}
              y={node.y + 35}
              text-anchor="middle"
              class="fill-current text-sm font-medium"
              style="font-family: ui-sans-serif, system-ui, sans-serif"
            >
              {truncate_node_name(node.name)}
            </text>
            
    <!-- Connection count indicator -->
            <g transform={"translate(#{node.x + 15}, #{node.y - 15})"}>
              <circle r="8" fill="currentColor" class="text-info" opacity="0.9" />
              <text
                x="0"
                y="0"
                text-anchor="middle"
                dominant-baseline="central"
                class="fill-current text-xs font-bold text-info-content"
                style="font-family: ui-sans-serif, system-ui, sans-serif"
              >
                {connection_count(node)}
              </text>
            </g>
          </g>
        <% end %>
        
    <!-- Network center point indicator -->
        <g transform={"translate(#{@width/2}, #{@height/2})"} opacity="0.3">
          <circle r="4" fill="currentColor" class="text-accent" />
          <circle r="8" fill="none" stroke="currentColor" stroke-width="1" class="text-accent">
            <animate
              attributeName="r"
              values="8;12;8"
              dur="4s"
              repeatCount="indefinite"
            />
          </circle>
        </g>
      </svg>
      
    <!-- Graph Controls Overlay -->
      <div class="network-graph-controls absolute top-2 sm:top-4 right-2 sm:right-4 flex sm:flex-row flex-col gap-1 sm:gap-2">
        <button
          class="btn btn-xs sm:btn-sm btn-circle btn-ghost bg-base-100/80 hover:bg-base-100 touch-target"
          phx-click="zoom_in"
          aria-label="Zoom in"
          title="Zoom In"
        >
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
              d="M12 6v6m0 0v6m0-6h6m-6 0H6"
            />
          </svg>
        </button>
        <button
          class="btn btn-xs sm:btn-sm btn-circle btn-ghost bg-base-100/80 hover:bg-base-100 touch-target"
          phx-click="zoom_out"
          aria-label="Zoom out"
          title="Zoom Out"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 12H6" />
          </svg>
        </button>
        <button
          class="btn btn-xs sm:btn-sm btn-circle btn-ghost bg-base-100/80 hover:bg-base-100 touch-target"
          phx-click="reset_view"
          aria-label="Reset view"
          title="Reset View"
        >
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
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
        </button>
      </div>
      
    <!-- Legend -->
      <div class="network-graph-legend absolute bottom-2 sm:bottom-4 left-2 sm:left-4 bg-base-100/90 p-2 sm:p-3 rounded-lg shadow">
        <h4 class="font-medium text-xs sm:text-sm mb-1 sm:mb-2">Node Status</h4>
        <div class="flex flex-col gap-0.5 sm:gap-1 text-xs">
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 rounded-full bg-success"></div>
            <span>Online</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 rounded-full bg-warning"></div>
            <span>Syncing</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 rounded-full bg-info"></div>
            <span>Connecting</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 rounded-full bg-error"></div>
            <span>Offline</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions for node positioning and styling

  defp calculate_node_positions(nodes, width, height) do
    center_x = width / 2
    center_y = height / 2
    radius = min(width, height) * @default_layout_radius_factor

    # Use a deterministic seed based on node count for consistent layout
    :rand.seed(:exsss, {length(nodes), width, height})

    nodes
    |> Enum.with_index()
    |> Enum.map(fn {node, index} ->
      angle = 2 * :math.pi() * index / length(nodes)

      # Add some randomness to make it more organic (but deterministic)
      noise_x = :rand.uniform(@position_noise_range) - div(@position_noise_range, 2)
      noise_y = :rand.uniform(@position_noise_range) - div(@position_noise_range, 2)

      x = center_x + radius * :math.cos(angle) + noise_x
      y = center_y + radius * :math.sin(angle) + noise_y

      Map.merge(node, %{x: x, y: y})
    end)
  end

  defp generate_connections(nodes) do
    # Generate connections between nodes (simplified - in real app this would come from actual P2P connections)
    for n1 <- nodes,
        n2 <- nodes,
        n1.id != n2.id,
        should_connect?(n1, n2) do
      status = connection_status(n1, n2)

      %{
        x1: n1.x,
        y1: n1.y,
        x2: n2.x,
        y2: n2.y,
        status: status,
        from: n1.id,
        to: n2.id
      }
    end
    |> Enum.uniq_by(fn conn -> Enum.sort([conn.from, conn.to]) end)
  end

  defp should_connect?(n1, n2) do
    # Simplified connection logic - connect nodes that are both online or one is syncing
    # Some random connections for visual variety
    (n1.status == :online and n2.status in [:online, :syncing]) or
      (n1.status == :syncing and n2.status == :online) or
      :rand.uniform() < @random_connection_probability
  end

  defp connection_status(n1, n2) do
    cond do
      n1.status == :online and n2.status == :online -> :active
      n1.status in [:online, :syncing] and n2.status in [:online, :syncing] -> :syncing
      true -> :inactive
    end
  end

  # Styling helper functions

  defp node_status_class(:online), do: "text-success"
  defp node_status_class(:syncing), do: "text-warning"
  defp node_status_class(:connecting), do: "text-info"
  defp node_status_class(_), do: "text-error"

  defp node_status_ring_class(:online), do: "text-success"
  defp node_status_ring_class(:syncing), do: "text-warning animate-pulse"
  defp node_status_ring_class(:connecting), do: "text-info animate-pulse"
  defp node_status_ring_class(_), do: "text-error"

  defp connection_status_class(:active), do: "text-success"
  defp connection_status_class(:syncing), do: "text-warning"
  defp connection_status_class(_), do: "text-base-content"

  defp node_icon_svg(specializations)
       when is_list(specializations) and length(specializations) > 0 do
    case hd(specializations) do
      :inference ->
        """
        <svg width="16" height="16" fill="currentColor" class="text-base-100" viewBox="0 0 16 16">
          <path d="M8 4.754a3.246 3.246 0 1 0 0 6.492 3.246 3.246 0 0 0 0-6.492zM5.754 8a2.246 2.246 0 1 1 4.492 0 2.246 2.246 0 0 1-4.492 0z"/>
          <path d="M9.796 1.343c-.527-1.79-3.065-1.79-3.592 0l-.094.319a.873.873 0 0 1-1.255.52l-.292-.16c-1.64-.892-3.433.902-2.54 2.541l.159.292a.873.873 0 0 1-.52 1.255l-.319.094c-1.79.527-1.79 3.065 0 3.592l.319.094a.873.873 0 0 1 .52 1.255l-.16.292c-.892 1.64.901 3.434 2.541 2.54l.292-.159a.873.873 0 0 1 1.255.52l.094.319c.527 1.79 3.065 1.79 3.592 0l.094-.319a.873.873 0 0 1 1.255-.52l.292.16c1.64.893 3.434-.902 2.54-2.541l-.159-.292a.873.873 0 0 1 .52-1.255l.319-.094c1.79-.527 1.79-3.065 0-3.592l-.319-.094a.873.873 0 0 1-.52-1.255l.16-.292c.893-1.64-.902-3.433-2.541-2.54l-.292.159a.873.873 0 0 1-1.255-.52l-.094-.319z"/>
        </svg>
        """

      :storage ->
        """
        <svg width="16" height="16" fill="currentColor" class="text-base-100" viewBox="0 0 16 16">
          <path d="M4 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H4zm0 1h8a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1z"/>
        </svg>
        """

      _ ->
        """
        <svg width="16" height="16" fill="currentColor" class="text-base-100" viewBox="0 0 16 16">
          <path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zM0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8z"/>
        </svg>
        """
    end
  end

  defp node_icon_svg(_), do: node_icon_svg([:generic])

  defp truncate_node_name(name) when is_binary(name) do
    if String.length(name) > 10 do
      String.slice(name, 0..7) <> "..."
    else
      name
    end
  end

  defp truncate_node_name(name), do: to_string(name)

  defp connection_count(_node) do
    # Simplified - would calculate actual connections in real implementation
    Enum.random(1..5)
  end
end
