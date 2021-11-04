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
end
