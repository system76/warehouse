defmodule Warehouse.Schemas.Kit do
  @moduledoc """
  `Ecto.Schema` for kits. Kits are mappings between `Warehouse.Schemas.Component`
  and `Warehouse.Schemas.Sku` with features like:

    - It takes X SKUs to satisfy 1 Component (Multi Quantity)
    - SKU A or SKU B can satisfy a Component (OR)

  As of right now, every row in this schema specifies an OR relationship. IE,
  any row, if the SKU has enough quantity, could satisfy the Component.

  Future versions will be rewritten to use a JSON blob for mapping instead of
  Foreign Key table references. This will allow more flexibility (needed for AND
  support), while also being easier to edit on the client side. It will also
  include features like:

    - 2 SKU As and 1 SKU B can satisfy a Component (AND)

  """

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
