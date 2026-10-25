defmodule Example.Endpoint do
  use Phoenix.Endpoint, otp_app: :example

  plug Plug.RequestId
  plug Plug.Logger
  plug Example.Router
end
