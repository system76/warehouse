defmodule Warehouse.Part do
  @moduledoc """
  This module handles high level functions for `Warehouse.Schemas.Part`.
  """

  import Ecto.Query

  alias Warehouse.{Repo, Schemas}

  @doc """
  Returns the amount of available parts to pick for a given SKU. This equates to
  all parts that:

  - Are in a storage area
  - Do not have an RMA description
  - Are not in an excluded picking list (QA, a couple of desks, etc)

  ## Examples

      iex> get_pickable_quantity_for_sku(sku_id)
      10

  """
  @spec get_pickable_quantity_for_sku(String.t()) :: non_neg_integer()
  def get_pickable_quantity_for_sku(sku_id) do
    query =
      from p in Schemas.Part,
        join: l in assoc(p, :location),
        where: p.sku_id == ^sku_id,
        where: is_nil(p.rma_description),
        where: l.area == :storage,
        where: l.id not in ^excluded_picking_locations()

    Repo.aggregate(query, :count, :id)
  end

  @doc """
  Returns a list of `Warehouse.Schemas.Location` IDs that are excluded from
  picking.

  ## Examples

      iex> excluded_picking_locations()
      [1, 2, 3]

  """
  def excluded_picking_locations() do
    Application.get_env(:warehouse, :exluded_picking_locations, [])
  end
end
