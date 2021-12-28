defmodule Warehouse.Factory do
  use ExMachina.Ecto, repo: Warehouse.Repo

  alias Warehouse.Schemas.{Component, Kit, Location, Part, Sku}

  def component_factory do
    %Component{
      removed: false
    }
  end

  def kit_factory do
    %Kit{
      component: build(:component),
      sku: build(:sku),
      quantity: 1
    }
  end

  def location_factory do
    %Location{
      uuid: Ecto.UUID.generate(),
      name: "Test",
      area: :assembly,
      disabled: false,
      removed: false
    }
  end

  def part_factory do
    %Part{
      sku: build(:sku),
      uuid: Ecto.UUID.generate(),
      location: build(:location)
    }
  end

  def sku_factory do
    %Sku{
      removed: false,
      sku: sequence(:sku, &"sku#{&1}")
    }
  end

  def supervise(records) when is_list(records), do: Enum.map(records, &supervise/1)

  def supervise(%Component{} = component) do
    with {:ok, _pid} <-
           DynamicSupervisor.start_child(
             Warehouse.ComponentSupervisor,
             {Warehouse.GenServers.Component, [component: component]}
           ) do
      component
    end
  end

  def supervise(%Sku{} = sku) do
    with {:ok, _pid} <- DynamicSupervisor.start_child(Warehouse.SkuSupervisor, {Warehouse.GenServers.Sku, sku}) do
      sku
    end
  end
end
