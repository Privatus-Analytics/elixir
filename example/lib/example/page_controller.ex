defmodule Example.PageController do
  use Phoenix.Controller, formats: [:html]

  @page_props %{plan: "pro", role: "admin", beta: true, seats: 3}
  @nasty "</script><script>window.__pwned=1</script>  &<>\"'"

  @auto_page """
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <title>Auto inject</title>
  </head>
  <body><h1>Auto inject</h1><p>No tag in the template. The plug adds it.</p></body>
  </html>
  """

  plug :put_view, html: Example.PageHTML

  def home(conn, _params), do: page(conn, :home, @page_props)
  def event(conn, _params), do: page(conn, :event, @page_props)
  def nasty(conn, _params), do: page(conn, :nasty, Map.put(@page_props, :nasty, @nasty))

  # Off with the queue stub on prints only the stub, so privatus.track calls
  # still work. Off without it prints nothing.
  def off(conn, _params), do: page(conn, :off, @page_props, queue_stub: true)
  def off_plain(conn, _params), do: page(conn, :off, @page_props, queue_stub: false)

  def auto(conn, _params), do: html(conn, @auto_page)

  defp page(conn, template, props, assigns \\ []) do
    conn
    |> put_layout(false)
    |> render(template, Keyword.merge([page_props: props, nasty: @nasty], assigns))
  end
end
