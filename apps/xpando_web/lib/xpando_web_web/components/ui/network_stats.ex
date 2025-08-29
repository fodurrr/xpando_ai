defmodule XpandoWebWeb.Components.UI.NetworkStats do
  @moduledoc """
  NetworkStats component for displaying network metrics using DaisyUI stats components.

  Follows Frontend Design Principles:
  1. Uses DaisyUI stats components as foundation
  2. Implements semantic theme colors for different metrics
  3. Responsive design with mobile-first approach
  4. Proper accessibility with ARIA labels
  """

  use Phoenix.Component

  attr :stats, :map, required: true, doc: "Network statistics map"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  attr :layout, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"],
    doc: "Layout orientation"

  def network_stats(assigns) do
    ~H"""
    <div
      class={[
        "stats shadow-lg",
        @layout == "vertical" && "stats-vertical lg:stats-horizontal",
        "w-full",
        @class
      ]}
      role="region"
      aria-label="Network statistics"
    >
      
    <!-- Total Nodes Stat -->
      <div class="stat">
        <div class="stat-figure text-primary" aria-hidden="true">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-8 w-8"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
        </div>
        <div class="stat-title">Total Nodes</div>
        <div class="stat-value text-primary" aria-label={"Total nodes: #{@stats.total_nodes}"}>
          {@stats.total_nodes}
        </div>
        <div class="stat-desc">Network participants</div>
      </div>
      
    <!-- Online Nodes Stat -->
      <div class="stat">
        <div class="stat-figure text-success" aria-hidden="true">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-8 w-8"
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
        </div>
        <div class="stat-title">Online Nodes</div>
        <div class="stat-value text-success" aria-label={"Online nodes: #{@stats.online_nodes}"}>
          {@stats.online_nodes}
        </div>
        <div class="stat-desc">Currently active</div>
      </div>
      
    <!-- Network Health Stat -->
      <div class="stat">
        <div class="stat-figure text-accent" aria-hidden="true">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-8 w-8"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
            />
          </svg>
        </div>
        <div class="stat-title">Network Health</div>
        <div
          class={[
            "stat-value",
            health_color_class(@stats.health_percentage)
          ]}
          aria-label={"Network health: #{@stats.health_percentage} percent"}
        >
          {@stats.health_percentage}%
        </div>
        <div class="stat-desc">{health_description(@stats.health_percentage)}</div>
      </div>
      
    <!-- Additional Stats if available -->
      <%= if Map.has_key?(@stats, :avg_response_time) do %>
        <div class="stat">
          <div class="stat-figure text-info" aria-hidden="true">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <div class="stat-title">Avg Response</div>
          <div
            class="stat-value text-info text-2xl"
            aria-label={"Average response time: #{@stats.avg_response_time} milliseconds"}
          >
            {@stats.avg_response_time}ms
          </div>
          <div class="stat-desc">Network latency</div>
        </div>
      <% end %>

      <%= if Map.has_key?(@stats, :total_connections) do %>
        <div class="stat">
          <div class="stat-figure text-secondary" aria-hidden="true">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"
              />
            </svg>
          </div>
          <div class="stat-title">P2P Connections</div>
          <div
            class="stat-value text-secondary"
            aria-label={"Total P2P connections: #{@stats.total_connections}"}
          >
            {@stats.total_connections}
          </div>
          <div class="stat-desc">Active links</div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions for health status styling
  defp health_color_class(percentage) when percentage >= 80, do: "text-success"
  defp health_color_class(percentage) when percentage >= 60, do: "text-warning"
  defp health_color_class(percentage) when percentage >= 40, do: "text-accent"
  defp health_color_class(_), do: "text-error"

  defp health_description(percentage) when percentage >= 90, do: "Excellent"
  defp health_description(percentage) when percentage >= 80, do: "Good"
  defp health_description(percentage) when percentage >= 60, do: "Fair"
  defp health_description(percentage) when percentage >= 40, do: "Poor"
  defp health_description(_), do: "Critical"
end
