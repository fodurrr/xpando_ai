defmodule XpandoWebWeb.Components.UI.NetworkStatsTest do
  use XpandoWebWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias XpandoWebWeb.Components.UI.NetworkStats

  describe "NetworkStats component" do
    test "renders basic network statistics" do
      stats = %{
        total_nodes: 10,
        online_nodes: 8,
        health_percentage: 80
      }

      html =
        render_component(&NetworkStats.network_stats/1, %{
          stats: stats,
          class: "test-stats"
        })

      assert html =~ "10"
      assert html =~ "8"
      assert html =~ "80%"
      assert html =~ "Total Nodes"
      assert html =~ "Online Nodes"
      assert html =~ "Network Health"
      assert html =~ "test-stats"
    end

    test "renders with vertical layout" do
      stats = %{
        total_nodes: 5,
        online_nodes: 3,
        health_percentage: 60
      }

      html =
        render_component(&NetworkStats.network_stats/1, %{
          stats: stats,
          layout: "vertical"
        })

      assert html =~ "stats-vertical lg:stats-horizontal"
      assert html =~ "5"
      assert html =~ "3"
      assert html =~ "60%"
    end

    test "includes proper accessibility attributes" do
      stats = %{
        total_nodes: 15,
        online_nodes: 12,
        health_percentage: 80
      }

      html =
        render_component(&NetworkStats.network_stats/1, %{stats: stats})

      assert html =~ "role=\"region\""
      assert html =~ "aria-label=\"Network statistics\""
      assert html =~ "aria-label=\"Total nodes: 15\""
      assert html =~ "aria-label=\"Online nodes: 12\""
      assert html =~ "aria-label=\"Network health: 80 percent\""
    end

    test "displays health status colors correctly" do
      excellent_stats = %{
        total_nodes: 10,
        online_nodes: 10,
        health_percentage: 95
      }

      html =
        render_component(&NetworkStats.network_stats/1, %{stats: excellent_stats})

      assert html =~ "text-success"
      assert html =~ "Excellent"

      poor_stats = %{
        total_nodes: 10,
        online_nodes: 3,
        health_percentage: 30
      }

      html =
        render_component(&NetworkStats.network_stats/1, %{stats: poor_stats})

      assert html =~ "text-error"
      assert html =~ "Critical"
    end

    test "renders additional metrics when present" do
      stats = %{
        total_nodes: 8,
        online_nodes: 6,
        health_percentage: 75,
        avg_response_time: 150,
        total_connections: 24
      }

      html =
        render_component(&NetworkStats.network_stats/1, %{stats: stats})

      assert html =~ "150ms"
      assert html =~ "Avg Response"
      assert html =~ "24"
      assert html =~ "P2P Connections"
      assert html =~ "aria-label=\"Average response time: 150 milliseconds\""
      assert html =~ "aria-label=\"Total P2P connections: 24\""
    end

    test "handles zero values gracefully" do
      empty_stats = %{
        total_nodes: 0,
        online_nodes: 0,
        health_percentage: 0
      }

      html =
        render_component(&NetworkStats.network_stats/1, %{stats: empty_stats})

      assert html =~ "0"
      assert html =~ "0%"
      assert html =~ "text-error"
      assert html =~ "Critical"
    end

    test "handles edge cases in health percentages" do
      # Test boundary conditions for health status
      test_cases = [
        {90, "text-success", "Excellent"},
        {80, "text-success", "Good"},
        {60, "text-warning", "Fair"},
        {40, "text-accent", "Poor"},
        {20, "text-error", "Critical"}
      ]

      for {percentage, expected_class, expected_description} <- test_cases do
        stats = %{
          total_nodes: 10,
          online_nodes: div(percentage * 10, 100),
          health_percentage: percentage
        }

        html =
          render_component(&NetworkStats.network_stats/1, %{stats: stats})

        assert html =~ expected_class
        assert html =~ expected_description
      end
    end
  end
end
