defmodule Example.Router do
  use Phoenix.Router

  import Plug.Conn

  @nonce "testnonce"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :content_security_policy
  end

  # Auto inject on this route only, so the other routes test the component alone.
  pipeline :auto_inject do
    plug PrivatusAnalytics.Plug
  end

  scope "/", Example do
    pipe_through :browser

    get "/", PageController, :home
    get "/event", PageController, :event
    get "/nasty", PageController, :nasty
    get "/off", PageController, :off
    get "/off-plain", PageController, :off_plain
  end

  scope "/", Example do
    pipe_through [:browser, :auto_inject]

    get "/auto", PageController, :auto
  end

  # The package reads the nonce from conn.assigns.csp_nonce, the way a real
  # app keeps it.
  def content_security_policy(conn, _opts) do
    conn
    |> assign(:csp_nonce, @nonce)
    |> put_resp_header(
      "content-security-policy",
      "script-src 'nonce-#{@nonce}' #{PrivatusAnalytics.Config.script_host()}"
    )
  end
end
