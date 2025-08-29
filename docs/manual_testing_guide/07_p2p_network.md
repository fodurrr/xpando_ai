# P2P Network Testing

Test the peer-to-peer networking capabilities and node communication.

## Node Manager Health Monitoring

The Node Manager tracks network health and connectivity.

```elixir
# ===== CHECK NETWORK STATE =====
# These functions monitor the P2P network health

# Get complete network state
network_state = XPando.Node.Manager.get_network_state()
IO.puts("🌐 Network State:")
IO.puts("  Current node: #{inspect(network_state.current_node)}")
IO.puts("  Cluster nodes: #{inspect(network_state.cluster_nodes)}")
IO.puts("  Network health: #{inspect(network_state.network_health)}")
IO.puts("  Total nodes: #{network_state.network_health.total_nodes}")
IO.puts("  Online nodes: #{network_state.network_health.online_nodes}")

# Get health statistics
health_stats = XPando.Node.Manager.get_health_stats()
IO.puts("📊 Health Stats:")
IO.puts("  Active nodes: #{health_stats.active_nodes}/#{health_stats.total_nodes}")
IO.puts("  Total connections: #{health_stats.total_connections}")
IO.puts("  Failed connections: #{health_stats.failed_connections}")
IO.puts("  Uptime: #{health_stats.uptime_seconds} seconds")

# Trigger manual heartbeat
result = XPando.Node.Manager.trigger_heartbeat()
IO.puts("💓 Heartbeat triggered: #{inspect(result)}")
```

## Multi-Node Cluster Testing

Test actual P2P communication between nodes.

```bash
# ===== START ADDITIONAL NODES (New Terminals) =====
# Each command starts a new Erlang node

# Terminal 2:
iex --sname node2@localhost -S mix

# Terminal 3:
iex --sname node3@localhost -S mix
```

```elixir
# ===== CONNECT NODES (In Main Terminal) =====

# Connect to other nodes
connected2 = Node.connect(:node2@localhost)
connected3 = Node.connect(:node3@localhost)

IO.puts("Connection to node2: #{connected2}")
IO.puts("Connection to node3: #{connected3}")

# List all connected nodes
connected_nodes = Node.list()
IO.puts("Connected nodes: #{inspect(connected_nodes)}")

# Check updated network state
network_state = XPando.Node.Manager.get_network_state()
IO.puts("Updated cluster size: #{length(network_state.cluster_nodes)}")
```

## PubSub Message Broadcasting

Test the internal message passing system.

```elixir
# ===== SUBSCRIBE TO NETWORK EVENTS =====
# This allows receiving real-time network updates

# Subscribe to different event channels
Phoenix.PubSub.subscribe(XpandoWeb.PubSub, "cluster:events")
Phoenix.PubSub.subscribe(XpandoWeb.PubSub, "network:updates")
Phoenix.PubSub.subscribe(XpandoWeb.PubSub, "network:topology")

IO.puts("📡 Subscribed to network events")

# Broadcast test message
result = Phoenix.PubSub.broadcast(
  XpandoWeb.PubSub, 
  "cluster:events", 
  {:test_message, "Hello P2P Network!"}
)

IO.puts("📡 Broadcast result: #{inspect(result)}")

# You should see the message in your IEx console
# Messages appear as: {:test_message, "Hello P2P Network!"}
# Note: In single-node mode, you'll receive your own broadcast
```

## Network Fault Tolerance

Test how the system handles node failures.

```elixir
# ===== SIMULATE NETWORK FAILURES =====

IO.puts("Simulating network partition...")

# Note: update_node_status function signature may need verification
# XPando.Node.Manager.update_node_status(:node2@localhost, :offline)
# XPando.Node.Manager.update_node_status(:node3@localhost, :connecting)
IO.puts("⚠️  Node status updates require multi-node setup to test properly")

# Check network health
health = XPando.Node.Manager.get_health_stats()
IO.puts("Network after failures:")
IO.puts("  Active: #{health.active_nodes}")
IO.puts("  Total: #{health.total_nodes}")

# Wait 2 seconds
Process.sleep(2000)

# Simulate recovery (requires multi-node setup)
IO.puts("Simulating recovery...")
# XPando.Node.Manager.update_node_status(:node2@localhost, :online)
# XPando.Node.Manager.update_node_status(:node3@localhost, :online)
IO.puts("⚠️  Recovery simulation requires multi-node setup")

# Check recovery
health_recovered = XPando.Node.Manager.get_health_stats()
IO.puts("Network after recovery:")
IO.puts("  Active: #{health_recovered.active_nodes}")
IO.puts("  Total: #{health_recovered.total_nodes}")
```

## Expected Outputs

- **Network state**: Shows current node name and connected cluster nodes
- **Health stats**: Active/total nodes ratio and connection metrics
- **Heartbeat**: Silent success or debug log messages
- **PubSub messages**: Appear in console when broadcast

## Next: [Advanced Testing Scenarios](08_advanced_testing.md)