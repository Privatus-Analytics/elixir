defmodule PrivatusAnalytics.PlugTest do
  use PrivatusAnalytics.Case, async: false

  import Plug.Conn
  import Plug.Test

  @snippet ~s(<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>)
  @page "<html><head><title>Hi</title></head><body>Hello</body></html>"

  defp run(body, opts \\ [], fun \\ & &1) do
    conn(:get, "/")
    |> fun.()
    |> PrivatusAnalytics.Plug.call(PrivatusAnalytics.Plug.init(opts))
    |> put_resp_content_type(Keyword.get(opts, :type, "text/html"))
    |> send_resp(Keyword.get(opts, :status, 200), body)
  end

  setup do
    configure(site_id: "pa_TEST123456", enabled: true)
  end

  test "adds the tag before </head> and fixes the content length" do
    conn = run(@page)

    assert conn.resp_body =~ "#{@snippet}\n</head>"

    assert get_resp_header(conn, "content-length") == [
             Integer.to_string(byte_size(conn.resp_body))
           ]
  end

  test "keeps the case of the closing head tag" do
    assert run("<HEAD></HEAD>").resp_body == "<HEAD>#{@snippet}\n</HEAD>"
  end

  test "does not add a second tag" do
    body = "<head>#{@snippet}</head>"

    assert run(body).resp_body == body
  end

  test "leaves JSON alone" do
    assert run(~s({"a":"</head>"}), type: "application/json").resp_body == ~s({"a":"</head>"})
  end

  test "leaves other statuses alone" do
    assert run(@page, status: 404).resp_body == @page
  end

  test "leaves HTML without a head alone" do
    assert run("<p>No head here</p>").resp_body == "<p>No head here</p>"
  end

  test "leaves Ajax requests alone" do
    conn = run(@page, [], &put_req_header(&1, "x-requested-with", "XMLHttpRequest"))

    assert conn.resp_body == @page
  end

  test "leaves encoded responses alone" do
    conn = run(@page, [], &put_resp_header(&1, "content-encoding", "gzip"))

    assert conn.resp_body == @page
  end

  test "adds nothing outside the enabled environments" do
    configure(enabled: nil)

    assert run(@page).resp_body == @page
  end

  test "uses plug options, the nonce assign and conn props" do
    conn =
      run(@page, [modules: ["vitals"]], fn conn ->
        conn |> assign(:csp_nonce, "xyz") |> PrivatusAnalytics.put_props(plan: "pro")
      end)

    assert conn.resp_body =~
             ~s|<script nonce="xyz">window.privatusPageProps=function(){return {"plan":"pro"}}</script>|

    assert conn.resp_body =~ ~s|data-modules="vitals" data-props="privatusPageProps" nonce="xyz"|
  end

  test "adds nothing when the tag is off, even with the queue stub on" do
    configure(enabled: false)

    assert run(@page, queue_stub: true).resp_body == @page
  end
end
