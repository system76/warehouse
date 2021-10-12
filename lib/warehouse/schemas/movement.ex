defmodule Warehouse.Schemas.Movement do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Warehouse.Schemas.Location
  alias Warehouse.Schemas.Part

  @type t :: %__MODULE__{
          from_location: Location.t(),
          to_location: Location.t(),
          part: Part.t()
        }

  @required_fields ~w(to_location_id part_id)a
  @optional_fields ~w(from_location_id)a
  @fields @required_fields ++ @optional_fields

  schema "inventory_movements" do
    belongs_to :from_location, Location
    belongs_to :to_location, Location
    belongs_to :part, Part

    timestamps(updated_at: false)
  end

  def changeset(part, attrs) do
    part
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:part)
    |> assoc_constraint(:from_location)
    |> assoc_constraint(:to_location)
  end
end
