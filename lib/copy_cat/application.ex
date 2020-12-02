defmodule CopyCat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      {CopyCat.Broadway, []}
    ]

    Logger.info("Starting Copy Cat")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CopyCat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
