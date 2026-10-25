defmodule PrivatusAnalytics.ComponentsTest do
  use PrivatusAnalytics.Case, async: false

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias PrivatusAnalytics.Components

  setup do
    configure(site_id: "pa_TEST123456", enabled: true)
  end

  test "renders the tag" do
    html = render_component(&Components.tag/1, %{})

    assert html =~
             ~s(<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>)
  end

  test "attributes override the config" do
    html =
      render_component(&Components.tag/1, modules: ["auto"], nonce: "n1", props: %{plan: "pro"})

    assert html =~
             ~s|<script nonce="n1">window.privatusPageProps=function(){return {"plan":"pro"}}</script>|

    assert html =~ ~s|data-modules="auto" data-props="privatusPageProps" nonce="n1"|
  end

  test "renders nothing when disabled" do
    assert render_component(&Components.tag/1, enabled: false) |> String.trim() == ""
  end

  test "event and click attributes work in HEEx" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <button {PrivatusAnalytics.event_attrs("Export CSV", format: "csv")}>Export</button>
      <a href="/signup" {PrivatusAnalytics.click_attrs("pricing.cta")}>Start</a>
      """)

    assert html =~
             ~s(<button data-privatus-event="Export CSV" data-privatus-prop-format="csv">Export</button>)

    assert html =~ ~s(<a href="/signup" data-privatus-click="pricing.cta">Start</a>)
  end

  test "the component in a HEEx template" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <head><Components.tag queue_stub={true} /></head>
      """)

    assert html =~ "<head><script>window.privatus=window.privatus||"
  end
end
