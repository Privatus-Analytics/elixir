defmodule PrivatusAnalytics.MixProject do
  use Mix.Project

  @version "1.0.1"
  @source_url "https://github.com/Privatus-Analytics/elixir"

  def project do
    [
      app: :privatus_analytics,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Privatus Analytics",
      source_url: @source_url,
      homepage_url: "https://privatusanalytics.com",
      # Mix.env/0 is only called when Mix is loaded (never in a release).
      xref: [exclude: [Mix]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:plug, "~> 1.14", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Adds the cookieless Privatus Analytics tracking script to Phoenix and Plug apps, " <>
      "with a function component, a Plug that adds it for you, and helpers for event attributes."
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Two Phase LLC"],
      links: %{
        "Homepage" => "https://privatusanalytics.com",
        "GitHub" => @source_url,
        "Docs" => "https://privatusanalytics.com/docs",
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w(lib mix.exs .formatter.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
