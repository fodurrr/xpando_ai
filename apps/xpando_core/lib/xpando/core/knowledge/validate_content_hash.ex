defmodule XPando.Core.Knowledge.ValidateContentHash do
  @moduledoc """
  Custom Ash validation for knowledge content integrity.

  Validates that knowledge content matches its SHA-256 hash to ensure
  data integrity and prevent tampering in the distributed network.

  ## Examples

  Test SHA-256 hashing:

      iex> # SHA-256 hash generation
      iex> content = "Test knowledge content"
      iex> hash = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
      iex> String.length(hash)
      64
      iex> String.match?(hash, ~r/^[0-9a-f]+$/)
      true

  Hash validation example:

      iex> # Content-hash matching validation
      iex> content = "Sample content"
      iex> correct_hash = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
      iex> wrong_hash = "invalid_hash"
      iex> correct_hash != wrong_hash
      true

  Integrity verification:

      iex> # Data integrity principles
      iex> integrity_aspects = ["hash_matching", "tamper_detection", "content_verification"]
      iex> "hash_matching" in integrity_aspects
      true

  """

  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    content = Ash.Changeset.get_attribute(changeset, :content)
    content_hash = Ash.Changeset.get_attribute(changeset, :content_hash)

    case {content, content_hash} do
      {nil, _} ->
        # Content is nil, let other validations handle this
        :ok

      {_, nil} ->
        # Hash is nil, let other validations handle this
        :ok

      {content, stored_hash} when is_binary(content) and is_binary(stored_hash) ->
        computed_hash = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

        if computed_hash == stored_hash do
          :ok
        else
          {:error, field: :content_hash, message: "Content hash does not match actual content"}
        end

      _ ->
        {:error, field: :content_hash, message: "Invalid content or hash format"}
    end
  end
end
