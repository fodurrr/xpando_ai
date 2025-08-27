# API Specification

Based on the Phoenix Channels + gRPC hybrid approach selected in the Tech Stack, xPando uses **Phoenix Channels for real-time P2P communication** and **gRPC for external integrations**. This combination provides optimal performance for distributed AI workloads while maintaining type safety and efficiency.

## Phoenix Channels API (Real-time P2P Communication)

Phoenix Channels handle all real-time communication between nodes, knowledge propagation, and live UI updates. Each channel serves a specific purpose in the distributed AI network.

### Node Network Channel
```elixir
defmodule XPandoWeb.NodeNetworkChannel do
  use XPandoWeb, :channel
  
  def join("node_network:" <> node_id, _payload, socket) do
    if authorized?(socket, node_id) do
      send(self(), :after_join)
      {:ok, assign(socket, :node_id, node_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
  
  # Handle P2P node discovery and status updates
  def handle_in("node_status", %{"status" => status, "metadata" => metadata}, socket) do
    node_id = socket.assigns.node_id
    
    # Update node status in database via Ash
    XPando.Core.Node
    |> Ash.Changeset.for_update(:update_status, %{status: status, metadata: metadata})
    |> Ash.update!()
    
    # Broadcast to all connected nodes
    broadcast!(socket, "node_status_update", %{
      node_id: node_id,
      status: status,
      metadata: metadata,
      timestamp: DateTime.utc_now()
    })
    
    {:reply, :ok, socket}
  end
  
  # Handle knowledge sharing between nodes
  def handle_in("share_knowledge", knowledge_payload, socket) do
    case create_knowledge_contribution(socket.assigns.node_id, knowledge_payload) do
      {:ok, contribution} ->
        # Broadcast new knowledge to Mother Core subscribers
        XPandoWeb.Endpoint.broadcast("mother_core:updates", "new_knowledge", %{
          contribution: contribution,
          node_id: socket.assigns.node_id
        })
        {:reply, {:ok, %{contribution_id: contribution.id}}, socket}
        
      {:error, changeset} ->
        {:reply, {:error, %{errors: translate_errors(changeset)}}, socket}
    end
  end
end
```

### Mother Core Channel
```elixir
defmodule XPandoWeb.MotherCoreChannel do
  use XPandoWeb, :channel
  
  def join("mother_core:updates", _payload, socket) do
    {:ok, socket}
  end
  
  # Handle knowledge validation requests
  def handle_in("validate_knowledge", %{"knowledge_id" => knowledge_id}, socket) do
    knowledge = XPando.Core.Knowledge |> Ash.get!(knowledge_id)
    
    # Trigger consensus validation process
    case XPando.Consensus.validate_knowledge(knowledge) do
      {:ok, validation_result} ->
        broadcast!(socket, "knowledge_validated", %{
          knowledge_id: knowledge_id,
          validation_result: validation_result,
          timestamp: DateTime.utc_now()
        })
        {:reply, :ok, socket}
        
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end
end
```

## gRPC API Specification (External Integrations)

gRPC provides high-performance, type-safe communication for external systems and mobile clients. Protocol Buffers define the service contracts with automatic code generation for multiple languages.

### Protocol Buffer Definitions

```protobuf
syntax = "proto3";

package xpando.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";

// Core message types
message Node {
  string id = 1;
  string public_key = 2;
  NodeType node_type = 3;
  repeated string specialization_domains = 4;
  double reputation_score = 5;
  NodeStatus status = 6;
  google.protobuf.Timestamp last_seen_at = 7;
  int32 connection_count = 8;
  map<string, string> metadata = 9;
}

enum NodeType {
  NODE_TYPE_UNSPECIFIED = 0;
  NODE_TYPE_GENESIS = 1;
  NODE_TYPE_EXPERT = 2;
  NODE_TYPE_PARTICIPANT = 3;
}

enum NodeStatus {
  NODE_STATUS_UNSPECIFIED = 0;
  NODE_STATUS_ONLINE = 1;
  NODE_STATUS_OFFLINE = 2;
  NODE_STATUS_CONNECTING = 3;
  NODE_STATUS_MAINTENANCE = 4;
}

message Knowledge {
  string id = 1;
  string content = 2;
  string content_hash = 3;
  double confidence_score = 4;
  KnowledgeType knowledge_type = 5;
  repeated string domain_tags = 6;
  int32 source_count = 7;
  ValidationStatus validation_status = 8;
  google.protobuf.Timestamp created_at = 9;
  google.protobuf.Timestamp updated_at = 10;
}

enum KnowledgeType {
  KNOWLEDGE_TYPE_UNSPECIFIED = 0;
  KNOWLEDGE_TYPE_INSIGHT = 1;
  KNOWLEDGE_TYPE_FACT = 2;
  KNOWLEDGE_TYPE_PROCEDURE = 3;
  KNOWLEDGE_TYPE_PATTERN = 4;
}

enum ValidationStatus {
  VALIDATION_STATUS_UNSPECIFIED = 0;
  VALIDATION_STATUS_PENDING = 1;
  VALIDATION_STATUS_VALIDATED = 2;
  VALIDATION_STATUS_DISPUTED = 3;
  VALIDATION_STATUS_ARCHIVED = 4;
}

message Contribution {
  string id = 1;
  string node_id = 2;
  string knowledge_id = 3;
  ContributionType contribution_type = 4;
  double quality_score = 5;
  int32 tokens_earned = 6;
  int32 peer_validations = 7;
  double contribution_weight = 8;
  google.protobuf.Timestamp created_at = 9;
}

enum ContributionType {
  CONTRIBUTION_TYPE_UNSPECIFIED = 0;
  CONTRIBUTION_TYPE_CREATION = 1;
  CONTRIBUTION_TYPE_VALIDATION = 2;
  CONTRIBUTION_TYPE_SYNTHESIS = 3;
  CONTRIBUTION_TYPE_CORRECTION = 4;
}

// Request/Response messages
message ListNodesRequest {
  NodeStatus status_filter = 1;
  string specialization_filter = 2;
  int32 page_size = 3;
  string page_token = 4;
}

message ListNodesResponse {
  repeated Node nodes = 1;
  string next_page_token = 2;
}

message CreateNodeRequest {
  string public_key = 1;
  NodeType node_type = 2;
  repeated string specialization_domains = 3;
}

message QueryKnowledgeRequest {
  repeated string domain_tags = 1;
  double min_confidence = 2;
  ValidationStatus validation_status = 3;
  int32 page_size = 4;
  string page_token = 5;
}

message QueryKnowledgeResponse {
  repeated Knowledge knowledge_items = 1;
  string next_page_token = 2;
}

message CreateContributionRequest {
  string node_id = 1;
  string knowledge_id = 2;
  ContributionType contribution_type = 3;
  string content = 4;
}

message ValidateKnowledgeRequest {
  string knowledge_id = 1;
  string validator_node_id = 2;
  double confidence_score = 3;
  string validation_notes = 4;
}

message ValidationResult {
  string knowledge_id = 1;
  bool is_valid = 2;
  double final_confidence = 3;
  int32 validator_count = 4;
  google.protobuf.Timestamp validated_at = 5;
}

// Service definitions
service NodeService {
  rpc ListNodes(ListNodesRequest) returns (ListNodesResponse);
  rpc CreateNode(CreateNodeRequest) returns (Node);
  rpc GetNode(GetNodeRequest) returns (Node);
  rpc UpdateNodeStatus(UpdateNodeStatusRequest) returns (Node);
}

message GetNodeRequest {
  string node_id = 1;
}

message UpdateNodeStatusRequest {
  string node_id = 1;
  NodeStatus status = 2;
  map<string, string> metadata = 3;
}

service KnowledgeService {
  rpc QueryKnowledge(QueryKnowledgeRequest) returns (QueryKnowledgeResponse);
  rpc GetKnowledge(GetKnowledgeRequest) returns (Knowledge);
  rpc ValidateKnowledge(ValidateKnowledgeRequest) returns (ValidationResult);
}

message GetKnowledgeRequest {
  string knowledge_id = 1;
}

service ContributionService {
  rpc CreateContribution(CreateContributionRequest) returns (Contribution);
  rpc ListContributions(ListContributionsRequest) returns (ListContributionsResponse);
}

message ListContributionsRequest {
  string node_id = 1;
  ContributionType contribution_type = 2;
  int32 page_size = 3;
  string page_token = 4;
}

message ListContributionsResponse {
  repeated Contribution contributions = 1;
  string next_page_token = 2;
}
```

### Elixir gRPC Service Implementation

```elixir
defmodule XPando.GRPC.NodeService do
  use GRPC.Server, service: Xpando.V1.NodeService.Service
  
  alias XPando.Core.Node
  alias Xpando.V1.{ListNodesRequest, ListNodesResponse, CreateNodeRequest}
  
  def list_nodes(%ListNodesRequest{} = request, _stream) do
    query_opts = build_query_options(request)
    
    nodes = Node
    |> Ash.Query.filter(build_filters(request))
    |> Ash.Query.load([:reputation_score, :connection_count])
    |> Ash.read!(query_opts)
    
    response = %ListNodesResponse{
      nodes: Enum.map(nodes, &to_protobuf/1),
      next_page_token: build_next_page_token(nodes, request.page_size)
    }
    
    {:ok, response}
  end
  
  def create_node(%CreateNodeRequest{} = request, _stream) do
    case Node
         |> Ash.Changeset.for_create(:create, %{
           public_key: request.public_key,
           node_type: request.node_type,
           specialization_domains: request.specialization_domains
         })
         |> Ash.create() do
      {:ok, node} ->
        {:ok, to_protobuf(node)}
      {:error, changeset} ->
        {:error, GRPC.RPCError.exception(GRPC.Status.invalid_argument(), 
          Ash.Error.to_error_class(changeset.errors))}
    end
  end
  
  def get_node(%{node_id: node_id}, _stream) do
    case Node |> Ash.get(node_id) do
      {:ok, node} -> {:ok, to_protobuf(node)}
      {:error, _} -> {:error, GRPC.RPCError.exception(GRPC.Status.not_found())}
    end
  end
  
  defp to_protobuf(%Node{} = node) do
    %Xpando.V1.Node{
      id: node.id,
      public_key: node.public_key,
      node_type: convert_node_type(node.node_type),
      specialization_domains: node.specialization_domains,
      reputation_score: Decimal.to_float(node.reputation_score),
      status: convert_node_status(node.status),
      last_seen_at: to_timestamp(node.last_seen_at),
      connection_count: node.connection_count,
      metadata: node.metadata || %{}
    }
  end
end

defmodule XPando.GRPC.KnowledgeService do
  use GRPC.Server, service: Xpando.V1.KnowledgeService.Service
  
  alias XPando.Core.Knowledge
  alias Xpando.V1.{QueryKnowledgeRequest, QueryKnowledgeResponse}
  
  def query_knowledge(%QueryKnowledgeRequest{} = request, _stream) do
    knowledge_items = Knowledge
    |> Ash.Query.filter(build_knowledge_filters(request))
    |> Ash.Query.sort(:confidence_score, :desc)
    |> Ash.read!()
    
    response = %QueryKnowledgeResponse{
      knowledge_items: Enum.map(knowledge_items, &knowledge_to_protobuf/1),
      next_page_token: build_next_page_token(knowledge_items, request.page_size)
    }
    
    {:ok, response}
  end
  
  def validate_knowledge(%{knowledge_id: knowledge_id, validator_node_id: node_id} = request, _stream) do
    case XPando.Consensus.validate_knowledge(knowledge_id, node_id, request) do
      {:ok, validation_result} ->
        {:ok, %Xpando.V1.ValidationResult{
          knowledge_id: knowledge_id,
          is_valid: validation_result.is_valid,
          final_confidence: validation_result.confidence,
          validator_count: validation_result.validator_count,
          validated_at: to_timestamp(DateTime.utc_now())
        }}
      {:error, reason} ->
        {:error, GRPC.RPCError.exception(GRPC.Status.invalid_argument(), reason)}
    end
  end
end
```

### Client SDK Generation

The Protocol Buffer definitions automatically generate client SDKs for multiple languages:

```bash
# Generate Elixir client
protoc --elixir_out=./lib --elixir_opt=package_prefix=xpando.v1 xpando.proto

# Generate Python client
protoc --python_out=./clients/python --grpc_python_out=./clients/python xpando.proto

# Generate TypeScript client (for Node.js integrations)
protoc --ts_out=./clients/typescript xpando.proto

# Generate Go client
protoc --go_out=./clients/go --go-grpc_out=./clients/go xpando.proto
```
