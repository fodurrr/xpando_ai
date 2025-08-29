defmodule XpandoWebWeb.Components.UI.NodeCard do
  @moduledoc """
  NodeCard component for displaying individual node information using DaisyUI.

  Follows the Frontend Design Principles with component-first approach:
  1. Uses DaisyUI card components as base
  2. Applies Tailwind utilities for customization
  3. Implements responsive design patterns
  4. Includes proper accessibility attributes
  """

  use Phoenix.Component

  attr :node, :map, required: true, doc: "The node struct to display"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :show_details, :boolean, default: false, doc: "Show detailed node information"

  slot :actions, doc: "Action buttons for the node card"

  def node_card(assigns) do
    ~H"""
    <div
      class={["card bg-base-100 shadow-lg", @class]}
      role="article"
      aria-label={"Node #{@node.name}"}
    >
      <div class="card-body">
        <!-- Node Header -->
        <div class="flex justify-between items-start mb-3">
          <div class="flex-1 min-w-0">
            <h3 class="card-title text-lg font-bold text-base-content truncate">
              {@node.name}
            </h3>
            <p class="text-sm text-base-content/70 font-mono">
              ID: {String.slice(to_string(@node.id), 0..7)}...
            </p>
          </div>
          
    <!-- Status Badge -->
          <div
            class={[
              "badge badge-lg font-medium",
              status_badge_class(@node.status)
            ]}
            role="status"
            aria-label={"Node status: #{@node.status}"}
          >
            <span class="sr-only">Status:</span>
            {format_status(@node.status)}
          </div>
        </div>
        
    <!-- Node Metrics (shown when show_details is true) -->
        <%= if @show_details do %>
          <div class="grid grid-cols-2 gap-4 mb-4">
            <%= if @node.reputation_score do %>
              <div class="stat bg-base-200 rounded-lg p-3">
                <div class="stat-title text-xs">Reputation</div>
                <div class="stat-value text-lg text-primary">
                  {@node.reputation_score}
                </div>
              </div>
            <% end %>

            <%= if @node.last_heartbeat do %>
              <div class="stat bg-base-200 rounded-lg p-3">
                <div class="stat-title text-xs">Last Seen</div>
                <div class="stat-value text-sm">
                  {format_last_heartbeat(@node.last_heartbeat)}
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
        
    <!-- Specializations -->
        <%= if @node.specializations not in [nil, []] do %>
          <div class="mb-4">
            <div class="text-sm font-medium text-base-content/70 mb-2">Specializations</div>
            <div class="flex flex-wrap gap-1" role="list" aria-label="Node specializations">
              <%= for specialization <- @node.specializations do %>
                <span class="badge badge-outline badge-sm" role="listitem">
                  {specialization}
                </span>
              <% end %>
            </div>
          </div>
        <% end %>
        
    <!-- Connection Health Indicator -->
        <div class="mb-4">
          <div class="flex items-center gap-2 mb-1">
            <span class="text-sm font-medium text-base-content/70">Connection Health</span>
            <div
              class={[
                "w-3 h-3 rounded-full",
                connection_health_indicator(@node.status)
              ]}
              aria-hidden="true"
            >
            </div>
          </div>
          <progress
            class={["progress w-full", connection_health_progress_class(@node.status)]}
            value={connection_health_value(@node.status)}
            max="100"
            aria-label={"Connection health: #{connection_health_value(@node.status)}%"}
          >
            {connection_health_value(@node.status)}%
          </progress>
        </div>
        
    <!-- Actions -->
        <%= if @actions != [] do %>
          <div class="card-actions justify-end pt-2 border-t border-base-300">
            {render_slot(@actions, @node)}
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Status badge styling following DaisyUI theme colors
  defp status_badge_class(:online), do: "badge-success"
  defp status_badge_class(:offline), do: "badge-error"
  defp status_badge_class(:syncing), do: "badge-warning"
  defp status_badge_class(:connecting), do: "badge-info"
  defp status_badge_class(_), do: "badge-ghost"

  defp format_status(:online), do: "Online"
  defp format_status(:offline), do: "Offline"
  defp format_status(:syncing), do: "Syncing"
  defp format_status(:connecting), do: "Connecting"
  defp format_status(status), do: status |> to_string() |> String.capitalize()

  defp connection_health_indicator(:online), do: "bg-success animate-pulse"
  defp connection_health_indicator(:syncing), do: "bg-warning animate-pulse"
  defp connection_health_indicator(:connecting), do: "bg-info animate-pulse"
  defp connection_health_indicator(_), do: "bg-error"

  defp connection_health_progress_class(:online), do: "progress-success"
  defp connection_health_progress_class(:syncing), do: "progress-warning"
  defp connection_health_progress_class(:connecting), do: "progress-info"
  defp connection_health_progress_class(_), do: "progress-error"

  defp connection_health_value(:online), do: 100
  defp connection_health_value(:syncing), do: 65
  defp connection_health_value(:connecting), do: 30
  defp connection_health_value(_), do: 0

  defp format_last_heartbeat(nil), do: "Never"

  defp format_last_heartbeat(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 -> "Just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m ago"
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)}h ago"
      true -> "#{div(diff_seconds, 86400)}d ago"
    end
  end
end
