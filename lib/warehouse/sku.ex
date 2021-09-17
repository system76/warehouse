defmodule Warehouse.Kit do
  @moduledoc """
  Handles high level functions related to `Warehouse.Schemas.Sku`. This includes
  calculating availablility, getting total demand, and updating information.
  """

  import Ecto.Query

  alias Warehouse.{Demand, Repo}
  alias Warehouse.Schemas.{Component, Kit, Sku}

  @doc """
  Returns the quantity available for a sku. This takes into account every part
  we have information on, the location of that part, and if it's been RMAed or
  not.

  ## Examples

      iex> available_quantity(%Sku{})
      4

  """
  @spec available_quantity(Sku.t) :: demand
  def kit_demands(kits) when is_list(kits) do
    kits
    |> Enum.map(&kit_demands/1)
    |> Enum.reduce(&Demand.merge_demands/1)
  end

  def kit_demands(%Kit{quantity: quantity, sku: sku}) do
    current_sku_count =
  end
end
