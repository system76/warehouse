defmodule Warehouse.Schemas.Part do
  use Ecto.Schema

  import Ecto.Changeset

  alias Warehouse.Schemas.{Location, Sku}

  @type t :: %__MODULE__{
          location: Location.t(),
          serial_number: String.t(),
          sku: Sku.t(),
          uuid: String.t()
        }

  schema "inventory_parts" do
    field :uuid, Ecto.UUID
    field :serial_number, :string
    field :assembly_build_id, :string
    field :rma_description, :string

    belongs_to :location, Location
    belongs_to :sku, Sku

    timestamps()
  end

  def changeset(part, attrs) do
    part
    |> cast(attrs, [:location_id, :serial_number, :assembly_build_id, :sku_id, :uuid])
    |> assoc_constraint(:sku)
    |> assoc_constraint(:location)
  end
end
