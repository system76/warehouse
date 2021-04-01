defmodule Warehouse.Broadway do
  use Broadway

  require Logger

  alias Broadway.Message

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
  @decorate transaction(:queue)
  def handle_message(_, %Message{data: data} = message, _context) do
    bottle =
      data
      |> URI.decode()
      |> Bottle.Core.V1.Bottle.decode()

    Bottle.RequestId.read(:queue, bottle)

    with {:error, reason} <- notify_handler(bottle.resource) do
      Logger.error(inspect(reason))
    end

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

  defp notify_handler({:part_created, message}) do
    Logger.metadata(user_id: message.user.id)
    Logger.info("Handling Part Created message")
    Inventory.receive_part(message)
  end

  defp notify_handler({:part_updated, message}) do
    Logger.metadata(user_id: message.user.id)
    Logger.info("Handling Part Updated message")
    Inventory.move_part(message)
  end

  defp notify_handler({event, _message}) do
    Logger.warn("Ignoring #{event} message")
    {:ok, :ignored}
  end
end
