defmodule PrivatusAnalytics.Config do
  @moduledoc """
  Reads the settings for the tracking script.

  Settings come from three places. The first one found wins:

    1. Options passed to the call (for example `PrivatusAnalytics.tag(modules: ["engage"])`).
    2. Application config, `config :privatus_analytics, ...`.
    3. Built-in defaults (and the `PRIVATUS_SITE_ID` and `PRIVATUS_SCRIPT_HOST`
       environment variables for the site id and script host).

  ## Which environments get the tag

  `enabled: true` or `enabled: false` forces the tag on or off. When `enabled`
  is not set, the tag prints only when the current environment is in
  `enabled_environments` (default `[:prod]`). The current environment is:

    * the `:env` setting, if you set it (we recommend
      `config :privatus_analytics, env: config_env()` in `config/config.exs`),
    * else `Mix.env()` when Mix is running (`mix phx.server`, `mix test`),
    * else `:prod`. Mix is not part of a release, so a release counts as production.
  """

  @default_host "https://privatusstats.com"

  @doc "The tracker origin used when nothing else is set."
  def default_host, do: @default_host

  @doc false
  def normalize(opts) when is_map(opts), do: opts
  def normalize(opts) when is_list(opts), do: Map.new(opts)
  def normalize(nil), do: %{}

  @doc false
  # The call option if given (even nil), else the app config, else the default.
  def option(opts, key, default \\ nil) do
    case Map.fetch(opts, key) do
      {:ok, value} -> value
      :error -> Application.get_env(:privatus_analytics, key, default)
    end
  end

  @doc "The site id (starts with `pa_`), or nil. Falls back to `PRIVATUS_SITE_ID`."
  def site_id(opts \\ %{}) do
    opts |> normalize() |> option(:site_id) |> present() ||
      present(System.get_env("PRIVATUS_SITE_ID"))
  end

  @doc "The origin that serves `/js/pa.js`, without a trailing slash."
  def script_host(opts \\ %{}) do
    host =
      present(opts |> normalize() |> option(:script_host)) ||
        present(System.get_env("PRIVATUS_SCRIPT_HOST")) || @default_host

    String.trim_trailing(host, "/")
  end

  @doc "Whether the tag should print for these options."
  def enabled?(opts \\ %{}) do
    opts = normalize(opts)

    case option(opts, :enabled) do
      true ->
        true

      false ->
        false

      _ ->
        environments = opts |> option(:enabled_environments, [:prod]) |> List.wrap()
        to_string(env(opts)) in Enum.map(environments, &to_string/1)
    end
  end

  @doc "The environment used to decide if the tag prints. See the module docs."
  def env(opts \\ %{}) do
    option(normalize(opts), :env) || mix_env() || :prod
  end

  defp mix_env do
    if Code.ensure_loaded?(Mix) and function_exported?(Mix, :env, 0), do: Mix.env()
  end

  defp present(nil), do: nil

  defp present(value) do
    case value |> to_string() |> String.trim() do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
