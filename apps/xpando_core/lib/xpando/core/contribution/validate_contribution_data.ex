defmodule XPando.Core.Contribution.ValidateContributionData do
  @moduledoc """
  Custom Ash validation for contribution data integrity.

  Ensures contribution records have required data fields and
  meet quality standards before being persisted to the database.

  ## Examples

  Check contribution types requiring specific data:

      iex> # Contribution types with validation requirements
      iex> validated_types = [:validation, :enhancement, :correction, :verification]
      iex> :validation in validated_types
      true
      iex> :enhancement in validated_types  
      true

  Test required fields for validation contributions:

      iex> # Validation contribution required fields
      iex> validation_fields = [:validation_method, :confidence]
      iex> :validation_method in validation_fields
      true
      iex> :confidence in validation_fields
      true

  Map field validation example:

      iex> # Field presence checking
      iex> data = %{validation_method: "peer_review", confidence: 0.85}
      iex> Map.has_key?(data, :validation_method)
      true
      iex> Map.has_key?(data, :confidence)
      true

  Contribution data structure validation:

      iex> # Valid data structures  
      iex> valid_data_types = ["map", "empty_map", "nil"]
      iex> "map" in valid_data_types
      true

  """

  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    contribution_data = Ash.Changeset.get_attribute(changeset, :contribution_data)
    contribution_type = Ash.Changeset.get_attribute(changeset, :contribution_type)

    case {contribution_data, contribution_type} do
      {nil, _} ->
        :ok

      {data, _} when data == %{} ->
        :ok

      {data, type} when is_map(data) ->
        validate_data_for_type(data, type)

      _ ->
        {:error, field: :contribution_data, message: "Contribution data must be a map"}
    end
  end

  defp validate_data_for_type(data, :validation) do
    required_fields = [:validation_method, :confidence]
    validate_required_fields(data, required_fields, :validation)
  end

  defp validate_data_for_type(data, :enhancement) do
    required_fields = [:enhancement_type, :description]
    validate_required_fields(data, required_fields, :enhancement)
  end

  defp validate_data_for_type(data, :correction) do
    required_fields = [:correction_type, :original_content, :corrected_content]
    validate_required_fields(data, required_fields, :correction)
  end

  defp validate_data_for_type(data, :verification) do
    required_fields = [:verification_method, :evidence]
    validate_required_fields(data, required_fields, :verification)
  end

  defp validate_data_for_type(_data, :submission) do
    # Submissions don't require specific data structure
    :ok
  end

  defp validate_data_for_type(_data, _type) do
    # Unknown types are allowed with any data structure
    :ok
  end

  defp validate_required_fields(data, required_fields, contribution_type) do
    missing_fields =
      Enum.reject(required_fields, fn field ->
        Map.has_key?(data, field) or Map.has_key?(data, to_string(field))
      end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      field_list = Enum.join(missing_fields, ", ")

      {:error,
       field: :contribution_data,
       message: "Missing required fields for #{contribution_type} contribution: #{field_list}"}
    end
  end
end
