defmodule Warehouse.Broadway do
  use Broadway
  use Spandex.Decorators

  require Logger

  alias Broadway.Message
  alias Warehouse.{Component, Part, Sku}

  def start_link(_opts) do
    producer_module = Application.fetch_env!(:warehouse, :producer)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: producer_module
      ],
      processors: [
        default: [concurrency: 2]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 2000
        ]
      ]
    )
  end

  @impl true
  @decorate trace(service: :warehouse, type: :function)
  def handle_message(_, %Message{data: data} = message, _context) do
    Logger.reset_metadata()

    bottle =
      data
      |> URI.decode()
      |> Bottle.Core.V1.Bottle.decode()

    Bottle.RequestId.read(:queue, bottle)

    notify_handler(bottle.resource)

    message
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))
      message
  end

  @impl true
  def handle_batch(_, messages, _, _) do
    messages
  end

  @impl true
  def handle_failed([failed_message], _context) do
    [failed_message]
  end

  def notify_handler({:build_picked, %{build: build, location: location, parts: parts}}) do
    Logger.metadata(build_id: build.id)
    Logger.info("Handling Build Picked message")

    part_uuids = Enum.map(parts, &Map.get(&1, :id))
    Part.pick_parts(part_uuids, build.id, location.id)
  end

  def notify_handler({:component_demand_updated, %{component_id: component_id, quantity: quantity}}) do
    Logger.metadata(component_id: component_id)

    with :error <- Component.update_component_demand(component_id, quantity) do
      Logger.warn("Unable to update component demand")
    end
  end

  def notify_handler({:part_created, %{part: %{id: part_id, sku: %{id: sku_id}}}}) do
    Logger.metadata(sku_id: sku_id, part_id: part_id)
    Logger.info("Handling Part Created message")
    Sku.update_sku_availability(sku_id)
  end

  def notify_handler({:part_updated, %{new: %{id: part_id, sku: %{id: sku_id}}}}) do
    Logger.metadata(sku_id: sku_id, part_id: part_id)
    Logger.info("Handling Part Updated message")
    Sku.update_sku_availability(sku_id)
  end

  def notify_handler({:component_kit_changed, %{component: %{id: component_id}}}) do
    Logger.metadata(component_id: component_id)
    Logger.info("Handling ComponentKitChanged message")

    case Component.update_component_kits(component_id) do
      :ok -> :ok
      :error -> Logger.error("Unable to update component demand")
    end
  end

  def notify_handler({event, message}) do
    Logger.warn("Ignoring #{event} message", resource: inspect(message))
    :ignored
  end

  def notify_handler(message) do
    Logger.error("Unable to handle unknown message", resource: inspect(message))
    :ignored
  end
end
