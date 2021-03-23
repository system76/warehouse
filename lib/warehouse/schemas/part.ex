defmodule Warehouse.Schemas.Part do
  use Ecto.Schema

  import Ecto.Changeset

  alias Warehouse.Schemas.{Location, Sku}

  schema "inventory_parts" do
    field :uuid, :string
    field :serial_number, :string

    belongs_to :location, Location
    belongs_to :sku, Sku

    timestamps()
  end

  def changeset(part, attrs) do
    part
    |> cast(attrs, [:location_id, :serial_number, :sku_id, :uuid])
    |> assoc_constraint(:sku)
    |> assoc_constraint(:location)
  end
end
