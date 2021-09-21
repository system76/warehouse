defmodule Warehouse.Schemas.Sku do
  use Ecto.Schema

  import Ecto.Query

  alias Warehouse.Schemas.Part

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          sku: String.t(),
          description: String.t(),
          available_quantity: non_neg_integer(),
          current_demand: non_neg_integer(),
          removed: boolean(),
          parts: [Part.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "inventory_skus" do
    field :sku, :string
    field :description, :string

    field :available_quantity, :integer, default: 0, virtual: true
    field :current_demand, :integer, default: 0, virtual: true

    field :removed, :boolean, default: false

    has_many :parts, Part

    timestamps()
  end

  def populate_available_quantity(query) do
    from s in query,
      join: p in assoc(s, :parts),
      join: l in assoc(p, :location),
      select_merge: %{available_quantity: count(p.id)},
      where: is_nil(p.rma_description),
      where: l.area == :storage,
      where: l.id not in ^excluded_picking_locations(),
      group_by: s.id
  end

  defp excluded_picking_locations() do
    Application.get_env(:warehouse, :exluded_picking_locations, [])
  end
end
