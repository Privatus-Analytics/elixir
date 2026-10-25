defmodule Example.PageHTML do
  use Phoenix.Component

  alias PrivatusAnalytics.Components

  attr :title, :string, required: true
  attr :conn, :any, required: true
  attr :page_props, :map, required: true
  slot :inner_block, required: true

  def layout(assigns) do
    ~H"""
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title>{@title}</title>
        <Components.tag conn={@conn} props={@page_props} queue_stub={true} />
      </head>
      <body>
        {render_slot(@inner_block)}
      </body>
    </html>
    """
  end

  def home(assigns) do
    ~H"""
    <.layout title="Home" conn={@conn} page_props={@page_props}>
      <h1>Home</h1>
    </.layout>
    """
  end

  def event(assigns) do
    ~H"""
    <.layout title="Events" conn={@conn} page_props={@page_props}>
      <h1>Events</h1>
      <button
        type="button"
        {PrivatusAnalytics.event_attrs("Report exported", format: "csv", source: "toolbar")}
      >
        Export report
      </button>
      <p><a href="#pricing" {PrivatusAnalytics.click_attrs("pricing.cta")}>Pricing</a></p>
      <form action="/event" method="get" {PrivatusAnalytics.event_attrs("Signup form")}>
        <button type="submit">Sign up</button>
      </form>
    </.layout>
    """
  end

  def nasty(assigns) do
    ~H"""
    <.layout title="Nasty" conn={@conn} page_props={@page_props}>
      <h1>Nasty values</h1>
      <button type="button" {PrivatusAnalytics.event_attrs("Nasty value", nasty: @nasty)}>
        Nasty
      </button>
    </.layout>
    """
  end

  def off(assigns) do
    ~H"""
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title>Off</title>
        <meta name="privatus-off-start" /><Components.tag
          conn={@conn}
          enabled={false}
          props={@page_props}
          queue_stub={@queue_stub}
        /><meta name="privatus-off-end" />
      </head>
      <body><h1>Off</h1></body>
    </html>
    """
  end
end
