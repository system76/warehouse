defmodule Warehouse.Schemas.Configuration do
  use Ecto.Schema

  alias Warehouse.Schemas.{Component, Sku}

  @type t :: %__MODULE__{
          component: Component.t(),
          quantity: integer(),
          sku: Sku.t()
        }

  schema "inventory_configurations" do
    field :quantity, :integer, default: 1

    belongs_to :component, Component
    belongs_to :sku, Sku
  end
end
