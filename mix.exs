defmodule Warehouse.MixProject do
  use Mix.Project

  def project do
    [
      app: :warehouse,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:appsignal, "~> 1.0"},
      {:bottle, github: "system76/bottle", branch: "elixir", sha: "63d3cf0"},
      {:broadway_sqs, "~> 0.6.0"},
      {:decimal, "~> 2.0", override: true},
      {:ecto_enum, "~> 1.4"},
      {:ecto_sql, "~> 3.5"},
      {:hackney, "~> 1.16"},
      {:jason, "~> 1.2", override: true},
      {:myxql, "~> 0.2"},
      {:saxy, "~> 1.1"},
      {:credo, "~> 1.3", only: [:dev, :test]},
      {:ex_machina, "~> 2.4", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
