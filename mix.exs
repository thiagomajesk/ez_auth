defmodule EzAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :ez_auth,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "storybook"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      quality: ["format --check-formatted", "compile --warnings-as-errors", "credo --strict"],
      storybook: ["run --no-halt -e 'EzAuth.Storybook.run()'"]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_view, "~> 1.0"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.0"},
      {:phoenix_storybook, "~> 0.8", only: :dev},
      {:phoenix_playground, "~> 0.1", only: :dev},
      {:postgrex, "~> 0.19", only: :test},
      {:mimic, "~> 1.11", only: :test},
      {:ex_machina, "~> 2.8", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
