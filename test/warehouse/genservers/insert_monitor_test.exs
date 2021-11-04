defmodule Warehouse.GenServers.InsertMonitorTest do
  use Warehouse.DataCase, async: false

  import Mox

  alias Warehouse.GenServers.InsertMonitor

  describe "init/0" do
    setup do
      stub(Warehouse.Clients.Assembly.Mock, :request_component_demands, fn -> [] end)
      :ok
    end

    test "starts all the SKU processes", context do
      sku = insert(:sku)
      assert Warehouse.SkuRegistry |> Registry.lookup(to_string(sku.id)) |> length() == 0

      start_and_wait_for_handle_continue({InsertMonitor, name: context.test})

      assert Warehouse.SkuRegistry |> Registry.lookup(to_string(sku.id)) |> length() == 1
    end

    test "starts all the Component processes", context do
      component = insert(:component)
      assert Warehouse.ComponentRegistry |> Registry.lookup(to_string(component.id)) |> length() == 0

      start_and_wait_for_handle_continue({InsertMonitor, name: context.test})

      assert Warehouse.ComponentRegistry |> Registry.lookup(to_string(component.id)) |> length() == 1
    end

    defp start_and_wait_for_handle_continue(childspec) do
      :erlang.trace(:new, true, [:call, :return_to])
      :erlang.trace_pattern({InsertMonitor, :handle_continue, 2}, true, [:local])

      pid = start_supervised!(childspec)

      assert_receive {:trace, ^pid, :call, {InsertMonitor, :handle_continue, [:warmup, _]}}
      assert_receive {:trace, ^pid, :return_to, {:gen_server, :try_dispatch, 4}}
    end
  end

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
