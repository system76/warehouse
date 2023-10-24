defmodule Warehouse.Schemas.Movement do
  use Ecto.Schema

  import Ecto.Changeset

  alias Warehouse.Schemas.Location
  alias Warehouse.Schemas.Part

  @type t :: %__MODULE__{
          location: Location.t(),
          part: Part.t()
        }

  schema "inventory_part_movements" do
    belongs_to :location, Location
    belongs_to :part, Part

    timestamps(updated_at: false)
  end

  def changeset(movement, attrs) do
    movement
    |> cast(attrs, [:location_id, :part_id])
    |> validate_required([:location_id, :part_id])
    |> assoc_constraint(:part)
    |> assoc_constraint(:location)
  end
end
