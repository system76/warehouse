defmodule Warehouse.Schemas.Part do
  use Ecto.Schema

  alias Warehouse.Schemas.{Location, Sku}

  schema "inventory_parts" do
    belongs_to Location, :location
    belongs_to Sku, :sku

    timestamps()
  end
end
