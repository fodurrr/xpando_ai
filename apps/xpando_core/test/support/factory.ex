defmodule XPando.Factory do
  use ExMachina.Ecto, repo: XPando.Repo

  def node_factory do
    %XPando.Core.Node{
      name: sequence("node"),
      public_key: generate_public_key(),
      private_key_hash: generate_hash(),
      node_signature: generate_signature(),
      endpoint: sequence("https://node-") <> ".xpando.network",
      port: 8080,
      status: :active,
      specializations: ["ai", "blockchain"],
      expertise_level: Decimal.new("7.5"),
      reputation_score: Decimal.new("75.0"),
      trust_rating: Decimal.new("0.750"),
      validation_accuracy: Decimal.new("0.850"),
      region: "us-east",
      last_seen_at: DateTime.utc_now()
    }
  end

  def knowledge_factory do
    content = "Sample knowledge content about distributed systems"

    %XPando.Core.Knowledge{
      title: "Distributed Systems Knowledge",
      content: content,
      content_hash: :crypto.hash(:sha256, content) |> Base.encode16(case: :lower),
      knowledge_type: :insight,
      category: "technology",
      tags: ["distributed", "systems", "consensus"],
      validation_status: :pending,
      confidence_score: Decimal.new("0.000"),
      consensus_threshold: Decimal.new("0.750"),
      source_type: :human_input,
      submitter: build(:node)
    }
  end

  def contribution_factory do
    %XPando.Core.Contribution{
      node: build(:node),
      knowledge: build(:knowledge),
      contribution_type: :validation,
      quality_score: Decimal.new("8.0"),
      accuracy_assessment: Decimal.new("0.850"),
      value_rating: Decimal.new("0.750"),
      novelty_factor: Decimal.new("0.600"),
      contribution_status: :under_review,
      contribution_data: %{
        validation_method: "peer_review",
        confidence: 0.85
      }
    }
  end

  defp generate_public_key do
    :crypto.strong_rand_bytes(64) |> Base.encode64()
  end

  defp generate_hash do
    :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
  end

  defp generate_signature do
    :crypto.strong_rand_bytes(128) |> Base.encode64()
  end
end
