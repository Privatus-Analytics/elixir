if Code.ensure_loaded?(Plug.Conn) do
  defmodule PrivatusAnalytics.Plug do
    @moduledoc """
    Adds the script tag just before `</head>` in HTML responses.

        # lib/my_app_web/router.ex
        pipeline :browser do
          # ...
          plug PrivatusAnalytics.Plug
        end

    Adding the plug is the switch. It changes only responses with status 200,
    a `text/html` content type and no `content-encoding` header. It skips Ajax
    requests (`x-requested-with: XMLHttpRequest`), pages without a `</head>`, and
    pages that already have the tag. It fixes the `content-length` header.

    Options are the same as for `PrivatusAnalytics.tag/1`, for example
    `plug PrivatusAnalytics.Plug, modules: ["engage", "auto"]`. The nonce is
    read from `conn.assigns.csp_nonce` (change the name with `nonce_assign:`).
    """

    @behaviour Plug

    import Plug.Conn

    @head_close ~r{</head>}i
    @marker "/js/pa.js"

    @impl true
    def init(opts), do: opts

    @impl true
    def call(conn, opts), do: register_before_send(conn, &inject(&1, opts))

    @doc false
    def inject(conn, opts) do
      opts = Keyword.put(opts, :conn, conn)

      # A tag that is off inserts nothing, not even the queue stub.
      with true <- injectable?(conn),
           true <- PrivatusAnalytics.enabled?(opts),
           body = IO.iodata_to_binary(conn.resp_body),
           false <- String.contains?(body, @marker),
           true <- Regex.match?(@head_close, body),
           tag when tag != "" <- PrivatusAnalytics.tag_string(opts) do
        body = Regex.replace(@head_close, body, fn head -> tag <> "\n" <> head end, global: false)

        %{conn | resp_body: body}
        |> put_resp_header("content-length", Integer.to_string(byte_size(body)))
      else
        _ -> conn
      end
    end

    defp injectable?(conn) do
      conn.state == :set and conn.status == 200 and conn.resp_body != nil and html?(conn) and
        get_resp_header(conn, "content-encoding") == [] and not ajax?(conn)
    end

    defp html?(conn) do
      case get_resp_header(conn, "content-type") do
        [type | _] -> type |> String.downcase() |> String.starts_with?("text/html")
        [] -> false
      end
    end

    defp ajax?(conn) do
      Enum.any?(
        get_req_header(conn, "x-requested-with"),
        &(String.downcase(&1) == "xmlhttprequest")
      )
    end
  end
end
