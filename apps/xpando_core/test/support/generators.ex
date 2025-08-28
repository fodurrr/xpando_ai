defmodule XPando.TestGenerators do
  @moduledoc """
  Ash-native test data generators for xPando domain resources.

  Provides generator functions using Ash.Generator for creating Node, Knowledge, 
  and Contribution test data that respects resource actions and business logic.
  """

  use Ash.Generator

  def test_node(opts \\ []) do
    changeset_generator(
      XPando.Core.Node,
      :register,
      defaults: [
        name: sequence(:node_name, &"test-node-#{&1}"),
        public_key: StreamData.repeatedly(&generate_public_key/0),
        private_key_hash: StreamData.repeatedly(&generate_hash/0),
        node_signature: StreamData.repeatedly(&generate_signature/0),
        endpoint: sequence(:endpoint, &"https://test-node-#{&1}.xpando.network"),
        port: 8080,
        specializations: ["ai", "blockchain"],
        expertise_level: StreamData.map(StreamData.integer(5..10), &Decimal.new("#{&1}.0")),
        region: StreamData.member_of(["us-east", "us-west", "eu-west", "asia-pacific"])
      ],
      overrides: opts
    )
  end

  def test_knowledge(opts \\ []) do
    content =
      StreamData.repeatedly(fn ->
        "Sample knowledge content about distributed systems - #{:rand.uniform(1000)}"
      end)

    submitter_id =
      case opts[:submitter_id] do
        nil -> once(:default_submitter, fn -> generate(test_node()).id end)
        id -> StreamData.constant(id)
      end

    changeset_generator(
      XPando.Core.Knowledge,
      :submit_for_validation,
      defaults: [
        submitter_node_id: submitter_id,
        title: sequence(:knowledge_title, &"Test Knowledge #{&1}"),
        content: content,
        knowledge_type: StreamData.member_of([:insight, :fact, :method, :theory]),
        category: StreamData.member_of(["technology", "science", "business", "mathematics"]),
        tags:
          StreamData.list_of(
            StreamData.member_of(["distributed", "systems", "ai", "blockchain", "consensus"]),
            min_length: 1,
            max_length: 3
          ),
        source_type: StreamData.member_of([:human_input, :ai_generated, :hybrid])
      ],
      overrides: opts
    )
  end

  def contribution(opts \\ []) do
    node_id =
      case opts[:node_id] do
        nil -> once(:default_node, fn -> generate(test_node()).id end)
        id -> StreamData.constant(id)
      end

    knowledge_id =
      case opts[:knowledge_id] do
        nil -> once(:default_knowledge, fn -> generate(test_knowledge()).id end)
        id -> StreamData.constant(id)
      end

    changeset_generator(
      XPando.Core.Contribution,
      :record_contribution,
      defaults: [
        node_id: node_id,
        knowledge_id: knowledge_id,
        contribution_type:
          StreamData.member_of([:submission, :validation, :enhancement, :curation]),
        quality_score: StreamData.map(StreamData.integer(60..95), &Decimal.new("#{&1}.0")),
        accuracy_assessment: StreamData.map(StreamData.integer(70..98), &Decimal.new("0.#{&1}")),
        value_rating: StreamData.map(StreamData.integer(50..90), &Decimal.new("0.#{&1}")),
        novelty_factor: StreamData.map(StreamData.integer(30..80), &Decimal.new("0.#{&1}")),
        contribution_data:
          StreamData.map(
            StreamData.tuple({
              StreamData.member_of(["peer_review", "automated", "expert_validation"]),
              StreamData.float(min: 0.5, max: 0.99)
            }),
            fn {method, confidence} ->
              %{validation_method: method, confidence: confidence}
            end
          )
      ],
      overrides: opts
    )
  end

  # Fast generators using Ash.Seed for when you need speed over business logic
  def fast_node(attrs \\ %{}) do
    public_key = generate_public_key()
    node_id = :crypto.hash(:sha256, public_key) |> Base.encode16(case: :lower)

    Ash.Seed.seed!(
      XPando.Core.Node,
      Map.merge(
        %{
          name: "fast-node-#{:rand.uniform(1000)}",
          public_key: public_key,
          node_id: node_id,
          private_key_hash: generate_hash(),
          node_signature: generate_signature(),
          endpoint: "https://fast-test-#{:rand.uniform(100_000)}.xpando.network",
          port: 8080,
          status: :active,
          specializations: ["ai"],
          expertise_level: Decimal.new("7.5"),
          reputation_score: Decimal.new("75.0"),
          trust_rating: Decimal.new("0.750"),
          validation_accuracy: Decimal.new("0.850"),
          region: "us-east",
          last_seen_at: DateTime.utc_now()
        },
        attrs
      )
    )
  end

  def fast_knowledge(attrs \\ %{}) do
    content = "Fast test knowledge content"
    submitter_id = attrs[:submitter_id] || fast_node().id

    Ash.Seed.seed!(
      XPando.Core.Knowledge,
      Map.merge(
        %{
          title: "Fast Test Knowledge",
          content: content,
          content_hash: :crypto.hash(:sha256, content) |> Base.encode16(case: :lower),
          knowledge_type: :insight,
          category: "technology",
          tags: ["test"],
          validation_status: :validated,
          confidence_score: Decimal.new("0.000"),
          consensus_threshold: Decimal.new("0.750"),
          source_type: :human_input,
          submitter_id: submitter_id
        },
        attrs
      )
    )
  end

  def fast_contribution(attrs \\ %{}) do
    node_id = attrs[:node_id] || fast_node().id
    knowledge_id = attrs[:knowledge_id] || fast_knowledge().id

    Ash.Seed.seed!(
      XPando.Core.Contribution,
      Map.merge(
        %{
          node_id: node_id,
          knowledge_id: knowledge_id,
          contribution_type: :validation,
          quality_score: Decimal.new("8.0"),
          accuracy_assessment: Decimal.new("0.850"),
          value_rating: Decimal.new("0.750"),
          novelty_factor: Decimal.new("0.600"),
          contribution_status: :active,
          peer_reviews: 0,
          positive_reviews: 0,
          impact_score: Decimal.new("0.0"),
          contribution_data: %{validation_method: "test", confidence: 0.85}
        },
        attrs
      )
    )
  end

  # Helper functions - For fast_node() that bypasses validation
  defp generate_public_key do
    # Generate Ed25519 key pair for valid signatures
    {public_key, _private_key} = :crypto.generate_key(:eddsa, :ed25519)
    Base.encode64(public_key)
  end

  defp generate_hash do
    :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
  end

  defp generate_signature do
    # Generate a valid Ed25519 signature for testing
    # Create a temporary key pair for signature generation
    {_public, private} = :crypto.generate_key(:eddsa, :ed25519)
    message = "test-signature-#{:rand.uniform(100_000)}"
    signature = :crypto.sign(:eddsa, :none, message, [private, :ed25519])
    Base.encode64(signature)
  end

  # Helper to generate valid Ed25519 key-signature pairs for proper registration tests
  def generate_valid_node_identity(endpoint) do
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
    signature = :crypto.sign(:eddsa, :none, endpoint, [private_key, :ed25519])

    %{
      public_key: Base.encode64(public_key),
      signature: Base.encode64(signature)
    }
  end
end
