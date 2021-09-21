defmodule Warehouse.Kit do
  @moduledoc """
  Handles high level functions related to `Warehouse.Schemas.Kit`. This includes
  calculating demand for skus in a kit, and updating kit information.
  """

  alias Warehouse.{AdditiveMap, Schemas, Sku}

  @doc """
  Returns a map of demands for every sku in the list of kits.

  ## Examples

      iex> kit_sku_demand([%Kit{sku_id: 1, quantity: 2}, %Kit{sku_id: 2, quantity: 1}], 8)
      %{1 => 8, 2 => 4}

  """
  @spec kit_sku_demand([Schemas.Kit.t()], integer) :: AdditiveMap.t()
  def kit_sku_demand(kits, demand) do
    availability = kit_sku_availability(kits)

    sku_demands =
      kits
      |> Enum.map(&{&1.sku_id, 0})
      |> Enum.into(%{})

    {sku_demands, remainder} =
      Enum.reduce_while(kits, {sku_demands, demand}, fn kit, {sku_demands, remainder} ->
        able_grabs = AdditiveMap.get(availability, kit.sku_id)
        new_remainder = max(remainder - able_grabs, 0)
        sku_demand = (remainder - new_remainder) * kit.quantity

        acc = {AdditiveMap.add(sku_demands, kit.sku_id, sku_demand), new_remainder}

        if new_remainder > 0, do: {:cont, acc}, else: {:halt, acc}
      end)

    # TODO: This should take into account old, deprecated, and removed skus.
    first_orderable_kit = hd(kits)
    AdditiveMap.add(sku_demands, first_orderable_kit.sku_id, remainder * first_orderable_kit.quantity)
  end

  @doc """
  Returns a map of skus in the kit, and the amount of times that sku could be
  picked.

  ## Examples

      iex> kit_sku_availability([%Kit{sku: %{id: 1}}])
      %{1 => 1}

  """
  @spec kit_sku_availability([Schemas.Kit.t()] | Schemas.Kit.t()) :: AdditiveMap.t()
  def kit_sku_availability(kits) when is_list(kits) do
    kits
    |> Enum.map(&kit_sku_availability/1)
    |> Enum.reduce(%{}, &AdditiveMap.merge/2)
  end

  def kit_sku_availability(%Schemas.Kit{quantity: quantity, sku_id: sku_id}) do
    sku = Sku.get_sku(sku_id)
    AdditiveMap.add(%{}, sku.id, floor(sku.available_quantity / quantity))
  end
end
