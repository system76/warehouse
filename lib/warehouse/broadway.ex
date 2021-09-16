defmodule Warehouse.Broadway do
  use Broadway
  use Spandex.Decorators

  require Logger

  alias Broadway.Message
  alias Warehouse.Inventory

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

    with {:error, reason} <- notify_handler(bottle.resource) do
      Logger.error(inspect(reason))
    end

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
    Inventory.pick_parts(parts, build, location)
  end

  def notify_handler({:part_created, message}) do
    Logger.metadata(part_id: message.part.id)
    Logger.info("Handling Part Created message")
    Inventory.create_part(message)
  end

  def notify_handler({:part_updated, message}) do
    Logger.metadata(part_id: message.new.id)
    Logger.info("Handling Part Updated message")
    Inventory.update_part(message)
  end

  def notify_handler({event, _message}) do
    Logger.warn("Ignoring #{event} message")
    :ignored
  end

  def notify_handler(message) do
    Logger.error("Unable to handle unknown message", resource: inspect(message))
    :ignored
  end
end
