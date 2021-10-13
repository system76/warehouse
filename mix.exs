defmodule Warehouse.MixProject do
  use Mix.Project

  def project do
    [
      app: :warehouse,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        warehouse: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:eex, :logger],
      mod: {Warehouse.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 2.0", override: true},
      {:bottle, github: "codeadict/bottle", ref: "e35cd45"},
      {:broadway_rabbitmq, "~> 0.6.0"},
      {:credo, "~> 1.3", only: [:dev, :test]},
      {:decimal, "~> 1.9.0", override: true},
      {:decorator, "~> 1.2"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.5"},
      {:ex_aws_sqs, "~> 3.2"},
      {:ex_aws, "~> 2.1.6"},
      {:ex_machina, "~> 2.4", only: :test},
      {:hackney, "~> 1.16"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2", override: true},
      {:logger_json, github: "Nebo15/logger_json", ref: "8e4290a"},
      {:mox, "~> 1.0", only: :test},
      {:myxql, "~> 0.4.0"},
      {:plug, "~> 1.12.1"},
      {:saxy, "~> 1.1"},
      {:spandex_datadog, "~> 1.1"},
      {:spandex, "~> 3.0.3"},
      {:telemetry, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
