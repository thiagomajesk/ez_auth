defmodule EzAuth.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/thiagomajesk/ez_auth"

  def project do
    [
      app: :ez_auth,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      name: "EzAuth",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Opinionated and batteries-included authentication for Phoenix applications."
  end

  defp package do
    [
      maintainers: ["Thiago Majesk Goulart"],
      licenses: ["AGPL-3.0-only"],
      links: %{"GitHub" => @url}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "README",
      source_url: @url,
      extras: [
        "README.md": [filename: "README"],
        "docs/ARCHITECTURE.md": [filename: "architecture"]
      ]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "storybook"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["test"],
      quality: ["format --check-formatted", "compile --warnings-as-errors", "credo --strict"],
      storybook: ["run --no-halt -e 'EzAuth.Storybook.run()'"]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_view, "~> 1.1"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:phoenix_storybook, "~> 0.8", only: :dev},
      {:phoenix_playground, "~> 0.1", only: :dev},
      {:postgrex, "~> 0.19", only: :test},
      {:mimic, "~> 1.11", only: :test},
      {:ex_machina, "~> 2.8", only: :test},
      {:ex_doc, "~> 0.40.2", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
