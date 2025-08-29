defmodule XpandoWebWeb.Components.UI.NodeDetail do
  @moduledoc """
  NodeDetail component for displaying comprehensive node metrics and information.

  Shows detailed node information including uptime, reputation, specializations,
  connection health, recent activity, and performance metrics using DaisyUI components.
  """

  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-2 sm:p-4"
      phx-click="close_node_detail"
      phx-target={@myself}
    >
      <div
        class="node-detail-modal bg-base-100 rounded-lg sm:rounded-xl shadow-2xl max-w-4xl w-full max-h-[95vh] sm:max-h-[90vh] overflow-hidden"
        phx-click-away="close_node_detail"
        phx-target={@myself}
        role="dialog"
        aria-labelledby="node-detail-title"
        aria-modal="true"
      >
        
    <!-- Header -->
        <div class="node-detail-header bg-primary text-primary-content p-4 sm:p-6">
          <div class="flex justify-between items-start">
            <div class="min-w-0 flex-1 pr-4">
              <h2 id="node-detail-title" class="text-xl sm:text-2xl font-bold mb-1 sm:mb-2 truncate">
                {@node.name}
              </h2>
              <p class="opacity-90 font-mono text-xs sm:text-sm break-all">
                ID: {format_node_id(@node.id)}
              </p>
            </div>
            <div class="flex items-center gap-3">
              <!-- Status Badge -->
              <div class={[
                "badge badge-lg font-medium",
                status_badge_class(@node.status)
              ]}>
                {format_status(@node.status)}
              </div>
              
    <!-- Close Button -->
              <button
                class="btn btn-sm btn-circle btn-ghost hover:btn-error"
                phx-click="close_node_detail"
                phx-target={@myself}
                aria-label="Close node details"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>
        
    <!-- Content -->
        <div class="node-detail-content p-3 sm:p-6 overflow-y-auto max-h-[calc(95vh-120px)] sm:max-h-[calc(90vh-140px)] mobile-scroll">
          <!-- Key Metrics Grid -->
          <div class="node-detail-stats grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 sm:gap-4 mb-4 sm:mb-6">
            <!-- Reputation Score -->
            <div class="stat bg-base-200 rounded-lg">
              <div class="stat-figure text-primary">
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
                    d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"
                  />
                </svg>
              </div>
              <div class="stat-title">Reputation Score</div>
              <div class="stat-value text-primary">
                {@node.reputation_score || 0}
              </div>
              <div class="stat-desc">Network trust level</div>
            </div>
            
    <!-- Uptime -->
            <div class="stat bg-base-200 rounded-lg">
              <div class="stat-figure text-success">
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
              <div class="stat-title">Uptime</div>
              <div class="stat-value text-success">
                {calculate_uptime(@node)}
              </div>
              <div class="stat-desc">Time online</div>
            </div>
            
    <!-- Last Heartbeat -->
            <div class="stat bg-base-200 rounded-lg">
              <div class="stat-figure text-accent">
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
              <div class="stat-title">Last Heartbeat</div>
              <div class="stat-value text-sm">
                {format_last_heartbeat(@node.last_heartbeat)}
              </div>
              <div class="stat-desc">Connection activity</div>
            </div>
          </div>
          
    <!-- Specializations -->
          <%= if @node.specializations not in [nil, []] do %>
            <div class="card bg-base-200 mb-6">
              <div class="card-body">
                <h3 class="card-title">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5 mr-2"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                    />
                  </svg>
                  Node Specializations
                </h3>
                <div class="flex flex-wrap gap-2">
                  <%= for specialization <- @node.specializations do %>
                    <div class="badge badge-primary badge-lg gap-2">
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
                          d="M5 13l4 4L19 7"
                        />
                      </svg>
                      {format_specialization(specialization)}
                    </div>
                  <% end %>
                </div>
                <p class="text-sm opacity-70 mt-2">
                  This node provides specialized services for {Enum.join(
                    Enum.map(@node.specializations, &format_specialization/1),
                    ", "
                  )}
                </p>
              </div>
            </div>
          <% end %>
          
    <!-- Connection Health -->
          <div class="card bg-base-200 mb-6">
            <div class="card-body">
              <h3 class="card-title">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
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
                Connection Health
              </h3>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Connection Status -->
                <div>
                  <div class="flex items-center gap-2 mb-2">
                    <span class="font-medium">Overall Status:</span>
                    <div class={[
                      "w-4 h-4 rounded-full",
                      connection_health_indicator(@node.status)
                    ]}>
                    </div>
                    <span class="text-sm">{format_status(@node.status)}</span>
                  </div>
                  <progress
                    class={["progress w-full", connection_health_progress_class(@node.status)]}
                    value={connection_health_value(@node.status)}
                    max="100"
                  >
                  </progress>
                  <div class="text-xs opacity-70 mt-1">
                    Health Score: {connection_health_value(@node.status)}%
                  </div>
                </div>
                
    <!-- Response Times -->
                <div>
                  <div class="font-medium mb-2">Response Metrics</div>
                  <div class="space-y-1 text-sm">
                    <div class="flex justify-between">
                      <span>Avg Response Time:</span>
                      <span class="font-mono">{simulate_response_time(@node)}ms</span>
                    </div>
                    <div class="flex justify-between">
                      <span>Success Rate:</span>
                      <span class="font-mono">{simulate_success_rate(@node)}%</span>
                    </div>
                    <div class="flex justify-between">
                      <span>Peer Connections:</span>
                      <span class="font-mono">{simulate_peer_count(@node)}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Recent Activity -->
          <div class="card bg-base-200 mb-6">
            <div class="card-body">
              <h3 class="card-title">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                  />
                </svg>
                Recent Activity
              </h3>

              <div class="timeline timeline-vertical">
                <%= for activity <- simulate_recent_activity(@node) do %>
                  <div class="timeline-item">
                    <div class="timeline-marker">
                      <div class={[
                        "w-3 h-3 rounded-full",
                        activity_marker_class(activity.type)
                      ]}>
                      </div>
                    </div>
                    <div class="timeline-content">
                      <div class="flex justify-between items-start">
                        <div>
                          <h4 class="font-medium text-sm">{activity.title}</h4>
                          <p class="text-xs opacity-70">{activity.description}</p>
                        </div>
                        <span class="text-xs opacity-60">{activity.timestamp}</span>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          
    <!-- Actions -->
          <div class="flex gap-2 justify-end">
            <button class="btn btn-outline" phx-click="ping_node" phx-target={@myself}>
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
                  d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"
                />
              </svg>
              Ping Node
            </button>
            <button class="btn btn-primary" phx-click="connect_to_node" phx-target={@myself}>
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
                  d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
                />
              </svg>
              Connect
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close_node_detail", _params, socket) do
    send(self(), {:close_node_detail})
    {:noreply, socket}
  end

  @impl true
  def handle_event("ping_node", _params, socket) do
    send(self(), {:toast, "info", "Ping sent to #{socket.assigns.node.name}"})
    {:noreply, socket}
  end

  @impl true
  def handle_event("connect_to_node", _params, socket) do
    send(self(), {:toast, "info", "Connection request sent to #{socket.assigns.node.name}"})
    {:noreply, socket}
  end

  # Helper functions

  defp format_node_id(id) when is_binary(id) do
    if String.length(id) > 16 do
      String.slice(id, 0..7) <> "..." <> String.slice(id, -8..-1)
    else
      id
    end
  end

  defp format_node_id(id), do: id |> to_string() |> format_node_id()

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

  defp format_specialization(:inference), do: "AI Inference"
  defp format_specialization(:storage), do: "Data Storage"
  defp format_specialization(:compute), do: "Compute"
  defp format_specialization(:networking), do: "Networking"
  defp format_specialization(spec), do: spec |> to_string() |> String.capitalize()

  defp calculate_uptime(node) do
    # Simulate uptime calculation - in real implementation would use actual timestamps
    case node.status do
      :online -> "#{Enum.random(90..99)}%"
      :syncing -> "#{Enum.random(70..89)}%"
      _ -> "#{Enum.random(0..30)}%"
    end
  end

  defp format_last_heartbeat(nil), do: "Never"

  defp format_last_heartbeat(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 -> "Just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)} minutes ago"
      diff_seconds < 86_400 -> "#{div(diff_seconds, 3600)} hours ago"
      true -> "#{div(diff_seconds, 86_400)} days ago"
    end
  end

  defp connection_health_indicator(:online), do: "bg-success animate-pulse"
  defp connection_health_indicator(:syncing), do: "bg-warning animate-pulse"
  defp connection_health_indicator(:connecting), do: "bg-info animate-pulse"
  defp connection_health_indicator(_), do: "bg-error"

  defp connection_health_progress_class(:online), do: "progress-success"
  defp connection_health_progress_class(:syncing), do: "progress-warning"
  defp connection_health_progress_class(:connecting), do: "progress-info"
  defp connection_health_progress_class(_), do: "progress-error"

  defp connection_health_value(:online), do: Enum.random(90..100)
  defp connection_health_value(:syncing), do: Enum.random(60..89)
  defp connection_health_value(:connecting), do: Enum.random(30..59)
  defp connection_health_value(_), do: Enum.random(0..29)

  # Simulation functions (would be replaced with real data in production)

  defp simulate_response_time(node) do
    case node.status do
      :online -> Enum.random(50..200)
      :syncing -> Enum.random(200..500)
      _ -> Enum.random(1000..3000)
    end
  end

  defp simulate_success_rate(node) do
    case node.status do
      :online -> Enum.random(95..100)
      :syncing -> Enum.random(80..94)
      _ -> Enum.random(0..50)
    end
  end

  defp simulate_peer_count(node) do
    case node.status do
      :online -> Enum.random(5..20)
      :syncing -> Enum.random(2..8)
      _ -> 0
    end
  end

  defp simulate_recent_activity(node) do
    base_activities = [
      %{
        type: :connection,
        title: "Peer Connection Established",
        description: "Connected to #{Enum.random(1..5)} new peers",
        timestamp: "2 minutes ago"
      },
      %{
        type: :sync,
        title: "Data Synchronization",
        description: "Synchronized 1.2MB of network data",
        timestamp: "5 minutes ago"
      },
      %{
        type: :inference,
        title: "AI Inference Request",
        description: "Processed #{Enum.random(10..50)} inference requests",
        timestamp: "12 minutes ago"
      },
      %{
        type: :heartbeat,
        title: "Heartbeat Sent",
        description: "Network heartbeat successful",
        timestamp: "15 minutes ago"
      }
    ]

    case node.status do
      :offline ->
        [
          %{
            type: :error,
            title: "Connection Lost",
            description: "Lost connection to network",
            timestamp: "1 hour ago"
          }
        ]

      _ ->
        Enum.take_random(base_activities, 3)
    end
  end

  defp activity_marker_class(:connection), do: "bg-success"
  defp activity_marker_class(:sync), do: "bg-info"
  defp activity_marker_class(:inference), do: "bg-primary"
  defp activity_marker_class(:heartbeat), do: "bg-accent"
  defp activity_marker_class(:error), do: "bg-error"
  defp activity_marker_class(_), do: "bg-base-content"
end
