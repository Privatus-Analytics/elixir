defmodule Example.MixProject do
  use Mix.Project

  # The conformance example app (Phoenix with HEEx). It uses the package from
  # this repo's own source (the path dependency below), not from Hex.
  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [mod: {Example.Application, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:privatus_analytics, path: ".."},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
