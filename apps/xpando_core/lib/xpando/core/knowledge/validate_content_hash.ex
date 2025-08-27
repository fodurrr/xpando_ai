defmodule XPando.Core.Knowledge.ValidateContentHash do
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
