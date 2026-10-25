defmodule PrivatusAnalytics do
  @moduledoc """
  Adds the cookieless Privatus Analytics tracking script to Phoenix and Plug apps.

  The package only prints HTML: the browser script tag and HTML attributes.
  It never sends events from your server, sets no cookies and never reads IP
  addresses or user agents.

  ## The tag

    * `PrivatusAnalytics.Components.tag/1` for HEEx layouts.
    * `tag/1` (safe HTML) and `tag_string/1` (plain string) for EEx or anything else.
    * `PrivatusAnalytics.Plug` adds the tag before `</head>` for you.

  ## Product analytics helpers

    * `event_attrs/2` sends an event when an element is clicked (or a form is submitted).
    * `click_attrs/1` names an element for click maps.
    * `put_props/2` and the `:props` option set page properties.
    * `props_json/1` gives page properties as JSON, for a LiveView hook.

  See `PrivatusAnalytics.Config` for every setting and how the environment is chosen.
  """

  require Logger

  alias PrivatusAnalytics.{Config, HTML, Props, Tag}

  @click_name ~r/\A[A-Za-z0-9_.:-]{1,100}\z/

  @typedoc "Options for the tag. Any setting from `PrivatusAnalytics.Config` plus `:nonce`, `:props`, `:queue_stub` and `:conn`."
  @type options :: keyword() | map()

  @typedoc "Event or page properties, as a map or keyword list."
  @type props :: map() | keyword()

  @typedoc "Attributes as `{name, value}` pairs, ready for `{...}` in HEEx."
  @type attrs :: [{String.t(), String.t()}]

  @doc """
  The script tag as safe HTML (`{:safe, iodata}`), ready for EEx and HEEx.

      <%= PrivatusAnalytics.tag(nonce: @csp_nonce) %>

  Without a site id or when the tag is not enabled, prints only the queue stub
  (with `queue_stub: true`) or nothing.
  """
  @spec tag(options()) :: {:safe, String.t()}
  def tag(opts \\ []), do: {:safe, tag_string(opts)}

  @doc "The script tag as a plain string. Empty when nothing should print."
  @spec tag_string(options()) :: String.t()
  def tag_string(opts \\ []), do: Tag.render(opts)

  @doc "Whether the tag prints for these options (site id set and enabled)."
  @spec enabled?(options()) :: boolean()
  def enabled?(opts \\ []), do: Tag.render?(opts)

  @doc """
  The official queue stub script, so `privatus.track` calls made before the
  tracker loads are kept. Also printed by the tag with `queue_stub: true`.
  """
  @spec queue_stub(keyword()) :: {:safe, String.t()}
  def queue_stub(opts \\ []) do
    open =
      case Keyword.get(opts, :nonce) do
        nil -> "<script>"
        nonce -> ~s(<script nonce="#{HTML.escape(nonce)}">)
      end

    {:safe, open <> Tag.queue_stub_js() <> "</script>"}
  end

  @doc """
  Attributes that send an event when the element is clicked. On a `<form>`
  the event is sent when the form is submitted.

      <button {PrivatusAnalytics.event_attrs("Export CSV", format: "csv")}>Export</button>

  Returns `[]` when the name is empty. Printed even when the tag is off, so
  your HTML is the same in development and production.
  """
  @spec event_attrs(String.t() | atom(), props()) :: attrs()
  def event_attrs(name, props \\ []) do
    case Props.event_name(name) do
      nil ->
        []

      name ->
        props =
          for {key, value} <- Props.for_attributes(props),
              do: {"data-privatus-prop-" <> key, value}

        [{"data-privatus-event", name} | props]
    end
  end

  @doc "Like `event_attrs/2`, as safe HTML for EEx: `<button <%= event_attrs_html(\"Export CSV\") %>>`."
  @spec event_attrs_html(String.t() | atom(), props()) :: {:safe, String.t()}
  def event_attrs_html(name, props \\ []), do: {:safe, event_attrs_string(name, props)}

  @doc "Like `event_attrs/2`, as a plain escaped string of attributes."
  @spec event_attrs_string(String.t() | atom(), props()) :: String.t()
  def event_attrs_string(name, props \\ []), do: name |> event_attrs(props) |> HTML.attributes()

  @doc """
  The attribute that names an element for click maps.

      <a href="/signup" {PrivatusAnalytics.click_attrs("pricing.cta")}>Start</a>

  The name must be 1 to 100 letters, digits or `_ . : -`. Any other name
  returns `[]` (and logs a warning outside production).
  """
  @spec click_attrs(String.t() | atom()) :: attrs()
  def click_attrs(name) do
    name = to_string(name)

    if Regex.match?(@click_name, name) do
      [{"data-privatus-click", name}]
    else
      if Config.env() |> to_string() != "prod" do
        Logger.warning(
          "PrivatusAnalytics.click_attrs/1 ignored #{inspect(name)}: use 1 to 100 letters, digits or _ . : -"
        )
      end

      []
    end
  end

  @doc "Like `click_attrs/1`, as safe HTML for EEx."
  @spec click_attrs_html(String.t() | atom()) :: {:safe, String.t()}
  def click_attrs_html(name), do: {:safe, click_attrs_string(name)}

  @doc "Like `click_attrs/1`, as a plain escaped string."
  @spec click_attrs_string(String.t() | atom()) :: String.t()
  def click_attrs_string(name), do: name |> click_attrs() |> HTML.attributes()

  @doc """
  Adds page properties for this request. They are sent with every pageview and
  event on the page. Use groups (plan, role), never anything that names a person.

      conn |> PrivatusAnalytics.put_props(%{plan: "pro", role: "admin"})

  The tag and the Plug read them from the conn. Calls merge.
  """
  @spec put_props(conn, props()) :: conn when conn: %{private: map()}
  def put_props(%{private: private} = conn, props) do
    key = Tag.private_key()
    current = Map.get(private, key) || %{}
    %{conn | private: Map.put(private, key, Enum.into(props, current))}
  end

  @doc """
  Page properties as a JSON object string, cleaned the same way as the tag does.
  Handy for a LiveView hook: `data-privatus-props={PrivatusAnalytics.props_json(%{plan: @plan})}`.
  """
  @spec props_json(props()) :: String.t()
  def props_json(props), do: props |> Props.for_json() |> Tag.props_json()
end
