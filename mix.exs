defmodule XPando.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      elixir: "~> 1.19-rc",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: [
        xpando: [
          version: "0.1.0",
          applications: [
            xpando_core: :permanent,
            xpando_web: :permanent,
            xpando_node: :permanent
          ]
        ]
      ]
    ]
  end

  defp deps do
    [
      {:ash_phoenix, "~> 2.3"},
      {:ash_authentication, "~> 4.9"},
      {:ash_postgres, "~> 2.6"},
      {:ash, "~> 3.5"},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      # Database (Ash-first approach)
      setup: ["ash.setup"],
      reset: ["ash.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.deploy": ["phx.digest"],

      # Development workflow
      "db.setup": ["ash.setup"],
      "db.reset": ["ash.setup"],

      # Ash-specific commands  
      "ash.generate": ["ash_postgres.generate_migrations"],
      "ash.gen": ["ash_postgres.generate_migrations"],

      # Quality & CI checks
      quality: ["format", "credo --strict", "compile"],
      "quality.full": ["format", "credo --strict", "compile", "test", "deps.audit"],
      "ci.local": ["format --check-formatted", "credo --strict", "compile --warnings-as-errors"],
      "ci.prepare": ["deps.get", "format", "credo --strict", "compile"],

      # Deprecated aliases (for migration period)
      "ecto.setup": ["ash.setup"],
      "ecto.reset": ["ash.setup"],
      "ecto.migrate": ["ash.setup"]
    ]
  end
end
