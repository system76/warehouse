defmodule Warehouse.Kit do
  @moduledoc """
  Handles high level functions related to `Warehouse.Schemas.Kit`. This includes
  calculating demand for skus in a kit, and updating kit information.
  """

  import Ecto.Query

  alias Warehouse.{AdditiveMap, Repo, Schemas, Sku}

  @typedoc """
  This represents a list of all options a person can pick from to fulfill a kit.
  It's verbose, but made for future expansions like having AND selections in
  kitting.

  As it stands, the `skus` list will only ever have one option. After Kitting
  gets upgraded and AND picking is included, the skus list would represent all
  skus needed to be picked to fulfill the kit.
  """
  @type picking_option :: %{
          available_quantity: non_neg_integer(),
          required_quantity: non_neg_integer(),
          skus: [
            %{
              id: integer(),
              sku: String.t(),
              description: String.t(),
              available_quantity: non_neg_integer(),
              required_quantity: non_neg_integer(),
              locations: [
                %{
                  id: String.t(),
                  uuid: String.t(),
                  name: String.t(),
                  available_quantity: non_neg_integer()
                }
              ]
            }
          ]
        }

  @doc """
  Returns a list of kits for a Component ID.

  ## Examples

      iex> get_component_kits("123")
      [%Kit{}, %Kit{}]

  """
  @spec get_component_kits(String.t()) :: [Schemas.Kit.t()]
  def get_component_kits(component_id) do
    Schemas.Kit
    |> where([k], k.component_id == ^component_id)
    |> Repo.all()
  end

  @doc """
  Gets the total availability of the kits.

  ## Examples

      iex> get_kit_availability(kit)
      4

  """
  @spec get_kit_availability(Schemas.Kit.t() | [Schemas.Kit.t()]) :: non_neg_integer()
  def get_kit_availability(kit) do
    kit
    |> kit_sku_availability()
    |> Map.values()
    |> Enum.sum()
  end

  @doc """
  Returns data used for picking parts. This is a semi complicated return value,
  so please check the `Warehouse.Kit.picking_option` type for more information.

  ## Examples

      iex> get_kit_picking_options(kit)
      %{}

  """
  @spec get_kit_picking_options(Schemas.Kit.t()) :: picking_option()
  def get_kit_picking_options(kit) do
    if sku = Sku.get_sku(kit.sku_id) do
      locations = Sku.get_sku_pickable_locations(kit.sku_id)
      sku_quantity = locations |> Enum.map(&Map.get(&1, :quantity)) |> Enum.sum()

      %{
        available_quantity: floor(sku_quantity / kit.quantity),
        required_quantity: 1,
        skus: [
          %{
            id: sku.id,
            sku: sku.sku,
            description: sku.description,
            available_quantity: sku_quantity,
            required_quantity: kit.quantity,
            locations: map_location_quantities(locations)
          }
        ]
      }
    else
      %{
        available_quantity: 0,
        required_quantity: 1,
        options: []
      }
    end
  end

  defp map_location_quantities(locations) do
    locations
    |> Enum.map(fn location ->
      %{
        id: location.id,
        uuid: location.uuid,
        name: location.name,
        available_quantity: location.quantity
      }
    end)
    |> Enum.sort_by(&Map.get(&1, :available_quantity))
  end

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
      |> Enum.map(&AdditiveMap.set(%{}, &1.sku_id, 0))
      |> Enum.reduce(%{}, &AdditiveMap.merge/2)

    {sku_demands, remainder} =
      Enum.reduce_while(kits, {sku_demands, demand}, fn kit, {sku_demands, remainder} ->
        able_grabs = AdditiveMap.get(availability, kit.sku_id)
        new_remainder = max(remainder - able_grabs, 0)
        sku_demand = (remainder - new_remainder) * kit.quantity

        acc = {AdditiveMap.add(sku_demands, kit.sku_id, sku_demand), new_remainder}

        if new_remainder > 0, do: {:cont, acc}, else: {:halt, acc}
      end)

    # TODO: This should take into account old, deprecated, and removed skus.
    if first_orderable_kit = List.first(kits) do
      AdditiveMap.add(sku_demands, first_orderable_kit.sku_id, remainder * first_orderable_kit.quantity)
    else
      sku_demands
    end
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
    %{available: available} = Sku.get_sku_quantity(sku_id)
    AdditiveMap.add(%{}, sku_id, floor(available / quantity))
  end
end
