defmodule Warehouse.Kit do
  @moduledoc """
  Handles high level functions related to `Warehouse.Schemas.Kit`. This includes
  calculating demand for skus in a kit, and updating kit information.
  """

  alias Warehouse.{Demand, Repo, Schemas, Sku}

  @doc """
  Returns a map of skus in the kit, and the amount of times that sku could be
  picked.

  ## Examples

      iex> kit_sku_availability([%Kit{sku: %{id: 1}}])
      %{1 => 1ss}

  """
  @spec kit_sku_availability([Kit.t] | Kit.t) :: %{required(integer) => non_neg_integer()}
  def kit_sku_availability(kits) when is_list(kits) do
    kits
    |> Enum.map(&kit_sku_demands/1)
    |> Map.merge()
  end

  @doc """
  Returns a map of skus in the kit, and the amount of times that sku could be
  picked.

  ## Examples

      iex> kit_sku_availability([%Kit{sku: %{id: 1}}])
      %{1 => 1}

  """
  @spec kit_sku_availability([Kit.t] | Kit.t) :: %{required(integer) => non_neg_integer()}
  def kit_sku_availability(kits) when is_list(kits) do
    kits
    |> Enum.map(&kit_sku_demands/1)
    |> Map.merge()
  end

  def kit_sku_availability(%Kit{quantity: quantity, sku_id: sku_id}) do
    sku = Sku.get_sku(sku_id)
    Map.put(%{}, sku.id, floor(sku.available_quantity / quantity))
  end
end
