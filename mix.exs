defmodule Warehouse.MixProject do
  use Mix.Project

  def project do
    [
      app: :warehouse,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      extra_applications: [:logger],
      mod: {Warehouse.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bottle, github: "system76/bottle", ref: "b3d741d"},
      {:broadway_rabbitmq, "~> 0.7.1"},
      {:credo, "~> 1.6", only: [:dev, :test]},
      {:decimal, "~> 2.0.0", override: true},
      {:decorator, "~> 1.4"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.7"},
      {:ecto_sql, "~> 3.7"},
      {:ex_machina, "~> 2.4", only: :test},
      {:hackney, "~> 1.16"},
      {:httpoison, "~> 1.8.0"},
      {:jason, "~> 1.2", override: true},
      {:logger_json, "~> 4.3"},
      {:mox, "~> 1.0", only: :test},
      {:myxql, "~> 0.5"},
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
