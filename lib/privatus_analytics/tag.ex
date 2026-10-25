defmodule PrivatusAnalytics.Tag do
  @moduledoc false
  # Builds the script tag (and the optional queue stub and page props scripts).

  alias PrivatusAnalytics.{Config, HTML, Props}

  @list_options [modules: "data-modules", excluded_paths: "data-exclude", domains: "data-domains"]
  @spa_modes ~w(auto history hash off)
  @props_function "privatusPageProps"
  @private_key :privatus_analytics_props

  @queue_stub "window.privatus=window.privatus||{q:[]};" <>
                "['track','pageview','props','optOut','optIn','ready'].forEach(function(m)" <>
                "{window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push(" <>
                "[m,Array.prototype.slice.call(arguments)])}})"

  def private_key, do: @private_key
  def queue_stub_js, do: @queue_stub

  @doc "Whether a tag prints for these options."
  def render?(opts) do
    opts = Config.normalize(opts)
    Config.site_id(opts) != nil and Config.enabled?(opts)
  end

  @doc "The full HTML as a string. Empty when no tag should print."
  def render(opts) do
    opts = Config.normalize(opts)

    if render?(opts) do
      nonce = nonce(opts)
      props = page_props(opts)

      [
        Config.option(opts, :queue_stub, false) == true && inline_script(@queue_stub, nonce),
        props != [] && inline_script(props_js(props), nonce),
        "<script " <> HTML.attributes(attributes(opts, props != [], nonce)) <> "></script>"
      ]
      |> Enum.filter(&is_binary/1)
      |> Enum.join("\n")
    else
      ""
    end
  end

  @doc "The cleaned page props for these options, merged from config, conn and call."
  def page_props(opts) do
    opts = Config.normalize(opts)
    conn = Map.get(opts, :conn)

    configured =
      case Application.get_env(:privatus_analytics, :props) do
        nil -> []
        fun when is_function(fun, 1) -> fun.(conn)
        fun when is_function(fun, 0) -> fun.()
        {module, function, args} -> apply(module, function, [conn | args])
        props -> props
      end

    from_conn = if is_map(conn), do: conn |> Map.get(:private, %{}) |> Map.get(@private_key)

    [configured, from_conn, Map.get(opts, :props)]
    |> Enum.map(&Props.for_json/1)
    |> Enum.reduce([], &merge/2)
    |> Enum.take(30)
  end

  # Later sources win. Keys keep the order they first appeared in.
  defp merge(newer, acc) do
    Enum.reduce(newer, acc, fn {key, _} = pair, acc ->
      if List.keymember?(acc, key, 0), do: List.keyreplace(acc, key, 0, pair), else: acc ++ [pair]
    end)
  end

  @doc "The JSON object for page props, safe inside a script element."
  def props_json(props), do: HTML.json({:object, props})

  defp props_js(props) do
    "window.#{@props_function}=function(){return " <> props_json(props) <> "}"
  end

  defp inline_script(js, nil), do: "<script>" <> js <> "</script>"

  defp inline_script(js, nonce),
    do: ~s(<script nonce="#{HTML.escape(nonce)}">) <> js <> "</script>"

  defp nonce(opts) do
    case Map.get(opts, :nonce) do
      nil ->
        assign = Config.option(opts, :nonce_assign, :csp_nonce)

        case Map.get(opts, :conn) do
          %{assigns: assigns} when is_map(assigns) -> assigns |> Map.get(assign) |> blank_to_nil()
          _ -> nil
        end

      nonce ->
        blank_to_nil(nonce)
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: to_string(value)

  defp attributes(opts, props?, nonce) do
    base = [
      {"defer", true},
      {"src", Config.script_host(opts) <> "/js/pa.js"},
      {"data-site", Config.site_id(opts)}
    ]

    # nil keeps the tracker default. An empty modules list loads none.
    lists =
      Enum.flat_map(@list_options, fn {name, attribute} ->
        case list(Config.option(opts, name)) do
          nil -> []
          [] when name != :modules -> []
          values -> [{attribute, Enum.join(values, ",")}]
        end
      end)

    spa = to_string(Config.option(opts, :spa))
    spa = if spa in @spa_modes and spa != "auto", do: [{"data-spa", spa}], else: []
    manual = if Config.option(opts, :manual) == true, do: [{"data-manual", "true"}], else: []
    props = if props?, do: [{"data-props", @props_function}], else: []

    extras =
      opts
      |> Config.option(:extra_attributes)
      |> Kernel.||([])
      |> Enum.reject(fn {_, value} -> is_nil(value) end)
      |> Enum.map(fn {name, value} -> {to_string(name), value} end)

    nonce = if nonce, do: [{"nonce", nonce}], else: []

    base ++ lists ++ spa ++ manual ++ props ++ extras ++ nonce
  end

  # nil stays nil. Anything else becomes a clean list of strings.
  defp list(nil), do: nil

  defp list(value) do
    value
    |> List.wrap()
    |> Enum.flat_map(&String.split(to_string(&1), ","))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
