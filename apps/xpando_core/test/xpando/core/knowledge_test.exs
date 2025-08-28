defmodule XPando.Core.KnowledgeTest do
  use XPando.DataCase

  describe "Knowledge resource" do
    test "can create knowledge using fast_knowledge" do
      knowledge = fast_knowledge()
      assert knowledge.id
      assert knowledge.title
      assert knowledge.content
      assert knowledge.content_hash
      assert knowledge.category
      assert knowledge.validation_status == :validated
    end

    test "can create knowledge with specific submitter" do
      submitter = fast_node()

      knowledge =
        fast_knowledge(%{
          title: "Test Knowledge with Submitter",
          submitter_id: submitter.id,
          content: "This is test content for knowledge validation"
        })

      assert knowledge.title == "Test Knowledge with Submitter"
      assert knowledge.submitter_id == submitter.id
      assert knowledge.content == "This is test content for knowledge validation"
    end

    test "content hash is generated correctly" do
      # Use the default content from fast_knowledge to ensure hash matches
      knowledge = fast_knowledge()
      expected_content = "Fast test knowledge content"
      expected_hash = :crypto.hash(:sha256, expected_content) |> Base.encode16(case: :lower)
      assert knowledge.content_hash == expected_hash
    end

    test "can read knowledge" do
      knowledge = fast_knowledge()
      # Try reading through the domain
      found_knowledge = Ash.read!(XPando.Core.Knowledge, domain: XPando.Core)
      knowledge_ids = Enum.map(found_knowledge, & &1.id)
      assert knowledge.id in knowledge_ids
    end

    test "can filter knowledge by category" do
      tech_knowledge = fast_knowledge(%{category: "technology"})

      query =
        XPando.Core.Knowledge
        |> Ash.Query.filter(category == "technology")

      knowledge = Ash.read!(query, domain: XPando.Core)
      knowledge_ids = Enum.map(knowledge, & &1.id)
      assert tech_knowledge.id in knowledge_ids
    end

    test "can filter knowledge by validation status" do
      validated_knowledge = fast_knowledge(%{validation_status: :validated})

      query =
        XPando.Core.Knowledge
        |> Ash.Query.filter(validation_status == :validated)

      knowledge = Ash.read!(query, domain: XPando.Core)
      knowledge_ids = Enum.map(knowledge, & &1.id)
      assert validated_knowledge.id in knowledge_ids
    end
  end
end
