defmodule Warehouse.Caster do
  @moduledoc """
  Encapsulate the logic to cast from Schemass to Bottles and back
  """

  alias Bottle.Inventory.V1.Part

  def cast(%Part{} = part) do
    %{
      location_id: part.location.id,
      serial_number: part.serial_number,
      sku_id: part.sku.id,
      uuid: part.id
    }
  end
end
