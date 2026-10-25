if Code.ensure_loaded?(Phoenix.Component) do
  defmodule PrivatusAnalytics.Components do
    @moduledoc """
    Phoenix function components.

    Put the tag in the `<head>` of your root layout:

        <PrivatusAnalytics.Components.tag nonce={assigns[:csp_nonce]} conn={@conn} />

    Every attribute is optional. An attribute you leave out uses your config.
    """

    use Phoenix.Component

    @options ~w(site_id script_host modules excluded_paths domains spa manual enabled
                enabled_environments env extra_attributes nonce props queue_stub conn)a

    @doc """
    The Privatus Analytics script tag.

    Prints nothing without a site id or when the tag is not enabled.
    """
    attr :site_id, :string, doc: "Overrides the site id."
    attr :script_host, :string, doc: "Overrides the script host."
    attr :modules, :list, doc: "Tracker modules, for example `[\"engage\", \"auto\"]`."
    attr :excluded_paths, :list, doc: "Path globs the tracker never counts."
    attr :domains, :any, doc: "Hostnames to count."
    attr :spa, :string, doc: "One of `auto`, `history`, `hash` or `off`."
    attr :manual, :boolean, doc: "`true` turns off the automatic pageview."
    attr :enabled, :boolean, doc: "`true` or `false` forces the tag on or off."
    attr :enabled_environments, :list, doc: "Environments that get the tag."
    attr :env, :atom, doc: "The current environment."
    attr :extra_attributes, :any, doc: "Other `data-*` attributes, as a map."
    attr :nonce, :string, doc: "Content Security Policy nonce for the script tags."
    attr :props, :any, doc: "Page properties, for example `%{plan: \"pro\"}`."
    attr :queue_stub, :boolean, doc: "`true` prints the queue stub before the tag."
    attr :conn, :any, doc: "The conn, for props set with `put_props/2` and the nonce assign."

    def tag(assigns) do
      assigns = assign(assigns, :html, PrivatusAnalytics.tag(Map.take(assigns, @options)))

      ~H"""
      {@html}
      """
    end
  end
end
