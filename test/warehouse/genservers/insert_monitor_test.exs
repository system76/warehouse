defmodule Warehouse.GenServers.InsertMonitorTest do
  use Warehouse.DataCase, async: false

  import Mox

  alias Warehouse.GenServers.InsertMonitor

  describe "handle_info/2" do
    setup context do
      stub(Warehouse.Clients.Assembly.Mock, :request_component_demands, fn -> [] end)
      start_supervised!({InsertMonitor, [name: context.test, fetch_interval: :timer.seconds(1)]})
      :ok
    end

    test "fetches newly inserted SKUs and starts their processes" do
      0 = Warehouse.SkuSupervisor |> DynamicSupervisor.which_children() |> length()

      insert_list(5, :sku)
      # Wait a bit over the configured fetch_interval
      Process.sleep(:timer.seconds(2))

      assert Warehouse.SkuSupervisor |> DynamicSupervisor.which_children() |> length() == 5
    end

    test "fetches newly inserted Components and starts their processes" do
      0 = Warehouse.ComponentSupervisor |> DynamicSupervisor.which_children() |> length()

      insert_list(3, :component)
      # Wait a bit over the configured fetch_interval
      Process.sleep(:timer.seconds(2))

      assert Warehouse.ComponentSupervisor |> DynamicSupervisor.which_children() |> length() == 3
    end
  end
end
