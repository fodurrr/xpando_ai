defmodule XpandoWebWeb.Components.UI.NodeCardTest do
  use XpandoWebWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias XpandoWebWeb.Components.UI.NodeCard

  describe "NodeCard component" do
    test "renders basic node information" do
      node = %{
        id: "test-node-1",
        name: "Test Node",
        status: :online,
        specializations: [:inference],
        reputation_score: 85,
        last_heartbeat: DateTime.utc_now()
      }

      html =
        render_component(&NodeCard.node_card/1, %{
          node: node,
          class: "test-class",
          show_details: true
        })

      assert html =~ "Test Node"
      # ID is truncated
      assert html =~ "test-nod"
      assert html =~ "Online"
      assert html =~ "badge-success"
      assert html =~ "inference"
      assert html =~ "85"
    end

    test "renders offline node correctly" do
      node = %{
        id: "offline-node",
        name: "Offline Node",
        status: :offline,
        specializations: [],
        reputation_score: nil,
        last_heartbeat: nil
      }

      html =
        render_component(&NodeCard.node_card/1, %{
          node: node
        })

      assert html =~ "Offline Node"
      assert html =~ "Offline"
      assert html =~ "badge-error"
      # Note: "Never" text is not displayed in basic NodeCard, only in NodeDetail
    end

    test "renders syncing node with specializations" do
      node = %{
        id: "syncing-node",
        name: "Syncing Node",
        status: :syncing,
        specializations: [:storage, :compute],
        reputation_score: 67,
        last_heartbeat: DateTime.add(DateTime.utc_now(), -300)
      }

      html =
        render_component(&NodeCard.node_card/1, %{
          node: node,
          show_details: true
        })

      assert html =~ "Syncing Node"
      assert html =~ "Syncing"
      assert html =~ "badge-warning"
      assert html =~ "storage"
      assert html =~ "compute"
      assert html =~ "67"
      assert html =~ "5m ago"
    end

    test "renders basic card without actions" do
      node = %{
        id: "action-node",
        name: "Node with Actions",
        status: :online,
        specializations: [],
        reputation_score: 90,
        last_heartbeat: DateTime.utc_now()
      }

      html = render_component(&NodeCard.node_card/1, %{node: node})

      assert html =~ "Node with Actions"
      assert html =~ "Online"
      assert html =~ "badge-success"
    end

    test "includes proper accessibility attributes" do
      node = %{
        id: "accessible-node",
        name: "Accessible Node",
        status: :online,
        specializations: [:inference],
        reputation_score: 85,
        last_heartbeat: DateTime.utc_now()
      }

      html =
        render_component(&NodeCard.node_card/1, %{node: node})

      assert html =~ "role=\"article\""
      assert html =~ "aria-label=\"Node Accessible Node\""
      assert html =~ "role=\"status\""
      assert html =~ "role=\"list\""
    end

    test "handles long node IDs correctly" do
      node = %{
        id: "very-long-node-id-that-should-be-truncated-properly",
        name: "Node with Long ID",
        status: :online,
        specializations: [],
        reputation_score: 75,
        last_heartbeat: DateTime.utc_now()
      }

      html =
        render_component(&NodeCard.node_card/1, %{node: node})

      assert html =~ "very-lon..."
      refute html =~ "very-long-node-id-that-should-be-truncated-properly"
    end

    test "connection health indicators work correctly" do
      online_node = %{
        id: "online-node",
        name: "Online Node",
        status: :online,
        specializations: [],
        reputation_score: 95,
        last_heartbeat: DateTime.utc_now()
      }

      html =
        render_component(&NodeCard.node_card/1, %{node: online_node})

      assert html =~ "progress-success"
      assert html =~ "bg-success animate-pulse"

      offline_node = %{
        id: "offline-node",
        name: "Offline Node",
        status: :offline,
        specializations: [],
        reputation_score: 0,
        last_heartbeat: nil
      }

      html =
        render_component(&NodeCard.node_card/1, %{node: offline_node})

      assert html =~ "progress-error"
      assert html =~ "bg-error"
    end
  end
end
