defmodule Warehouse.Schemas.Configuration do
  use Ecto.Schema

  import Ecto.Query

  alias Warehouse.Schemas.{Component, Sku}

  schema "inventory_configurations" do
    field :quantity, :integer, default: 1

    belongs_to :component, Component
    belongs_to :sku, Sku
  end

  @doc """
  Given a query for `WareHouse.Schemas.Configuration` with what every kind of
  filtering you give, this query will filters parts to only ones available. This
  can then be feeded into to `available_sum/1` function below to get the amount
  of parts available.

  ## Example

      iex> Configuration
      iex> |> where([c], c.sku_id == "123")
      iex> |> query_available_parts()
      iex> |> Repo.all()
      [%Configuration{sku: %Warehouse.Schemas.Sku{parts: []}}]

  """
  def query_available_parts(query) do
    from c in query,
      join: s in assoc(c, :sku),
      join: p in assoc(s, :parts),
      join: l in assoc(p, :location),
      where: l.area == :storage,
      where: is_nil(p.assembly_build_id),
      where: is_nil(p.rma_description),
      preload: [sku: {s, parts: p}]
  end

  @doc """
  Returns the total amount of available quantity for a configuration. Requires
  the parts attached to the sku to be loaded. Use the above `available_query/1`.
  """
  def available_sum(%{sku: %{parts: parts}, quantity: quantity}) do
    parts
    |> length()
    |> div(quantity)
  end
end
