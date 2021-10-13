defmodule Warehouse.Caster do
  @moduledoc """
  This module is responsible for casting structs between our internal structure,
  and `Bottle`.
  """

  alias Warehouse.Schemas.{Component, Location, Movement, Part, Sku}

  def cast_picking_options(map, level \\ :root)

  def cast_picking_options(map, :root),
    do: Enum.map(map, &cast_picking_options(&1, :options))

  def cast_picking_options(map, :options) do
    %{
      available_quantity: Map.get(map, :available_quantity, 0),
      required_quantity: Map.get(map, :required_quantity, 0),
      skus: map |> Map.get(:skus, []) |> Enum.map(&cast_picking_options(&1, :skus))
    }
  end

  def cast_picking_options(map, :skus) do
    %{
      sku: cast(struct(Sku, map)),
      available_quantity: Map.get(map, :available_quantity, 0),
      required_quantity: Map.get(map, :required_quantity, 0),
      locations: map |> Map.get(:locations, []) |> Enum.map(&cast_picking_options(&1, :locations))
    }
  end

  def cast_picking_options(map, :locations) do
    %{
      location: cast(struct(Location, map)),
      available_quantity: Map.get(map, :available_quantity, 0)
    }
  end

  @spec cast(Component.t()) :: Bottle.Inventory.V1.Component.t()
  def cast(%Component{} = component) do
    Bottle.Inventory.V1.Component.new(id: to_string(component.id))
  end

  @spec cast(Sku.t()) :: Bottle.Inventory.V1.Sku.t()
  def cast(%Sku{} = sku) do
    Bottle.Inventory.V1.Sku.new(
      id: to_string(sku.id),
      name: sku.sku,
      description: sku.description
    )
  end

  @spec cast(Location.t()) :: Bottle.Inventory.V1.Location.t()
  def cast(%Location{} = location) do
    Bottle.Inventory.V1.Location.new(
      id: to_string(location.uuid),
      name: location.name
    )
  end

  @spec cast(Movement.t()) :: Bottle.Inventory.V1.Movement.t()
  def cast(%Movement{} = movement) do
    Bottle.Inventory.V1.Movement.new(
      id: to_string(movement.id),
      part: cast_movement_part(movement.part),
      from_location: if(is_nil(movement.from_location), do: nil, else: cast(movement.from_location)),
      to_location: cast(movement.to_location),
      inserted_at: NaiveDateTime.to_iso8601(movement.inserted_at)
    )
  end

  @spec cast_movement_part(Part.t()) :: Bottle.Inventory.V1.Part.t()
  defp cast_movement_part(%Part{} = part) do
    Bottle.Inventory.V1.Part.new(
      id: to_string(part.id),
      serial_number: part.serial_number,
      rma_description: part.rma_description
    )
  end
end
