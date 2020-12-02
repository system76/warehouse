defmodule CopyCat.Broadway do
  use Broadway
  use Appsignal.Instrumentation.Decorators

  require Logger

  alias Broadway.Message

  def start_link(_opts) do
    producer_module = Application.fetch_env!(:copy_cat, :producer)

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
  def handle_message(_, %Message{} = message, _context) do
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
end
