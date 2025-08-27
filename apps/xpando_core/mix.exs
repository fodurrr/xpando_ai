defmodule XpandoCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :xpando_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18.1",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {XPandoCore.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 3.5"},
      {:ash_postgres, "~> 2.6"},
      {:ash_authentication, "~> 4.9"},
      {:ash_phoenix, "~> 2.3"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:picosat_elixir, "~> 0.2"},
      # Testing utilities (Ash-native)
      {:stream_data, "~> 1.1", only: :test}
    ]
  end
end
