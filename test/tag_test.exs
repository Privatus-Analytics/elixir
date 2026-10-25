defmodule PrivatusAnalytics.TagTest do
  use PrivatusAnalytics.Case, async: false

  @snippet ~s(<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>)

  setup do
    configure(site_id: "pa_TEST123456", enabled: true)
  end

  test "prints the basic snippet" do
    assert PrivatusAnalytics.tag_string() == @snippet
    assert PrivatusAnalytics.tag() == {:safe, @snippet}
  end

  test "prints nothing without a site id" do
    configure(site_id: nil)

    assert PrivatusAnalytics.tag_string() == ""
  end

  test "prints nothing outside the enabled environments" do
    configure(enabled: nil)

    assert PrivatusAnalytics.tag_string() == ""
    refute PrivatusAnalytics.enabled?()
  end

  test "adds modules and exclusions" do
    configure(modules: ~w(engage auto), excluded_paths: ["/admin/*", "/preview/*"])
    tag = PrivatusAnalytics.tag_string()

    assert tag =~ ~s(data-modules="engage,auto")
    assert tag =~ ~s(data-exclude="/admin/*,/preview/*")
  end

  test "an empty modules list loads none" do
    configure(modules: [])

    assert PrivatusAnalytics.tag_string() =~ ~s(data-modules="")
  end

  test "an empty exclusion list prints nothing" do
    configure(excluded_paths: [])

    refute PrivatusAnalytics.tag_string() =~ "data-exclude"
  end

  test "adds domains, spa mode and manual mode" do
    configure(domains: "example.com, www.example.com", spa: "hash", manual: true)
    tag = PrivatusAnalytics.tag_string()

    assert tag =~ ~s(data-domains="example.com,www.example.com")
    assert tag =~ ~s(data-spa="hash")
    assert tag =~ ~s(data-manual="true")
  end

  test "ignores an unknown spa mode and the auto default" do
    configure(spa: "bogus")
    refute PrivatusAnalytics.tag_string() =~ "data-spa"
    configure(spa: :auto)
    refute PrivatusAnalytics.tag_string() =~ "data-spa"
  end

  test "escapes attribute values" do
    configure(excluded_paths: [~s(/a"b)])

    assert PrivatusAnalytics.tag_string() =~ ~s(data-exclude="/a&quot;b")
  end

  test "per call options override the configuration" do
    configure(modules: ["engage"])

    assert PrivatusAnalytics.tag_string(modules: ["vitals"]) =~ ~s(data-modules="vitals")
    assert PrivatusAnalytics.tag_string(site_id: "pa_OTHER") =~ ~s(data-site="pa_OTHER")
    assert PrivatusAnalytics.tag_string(enabled: false) == ""
  end

  test "adds extra attributes and a nonce" do
    configure(extra_attributes: %{"data-mask" => "/orders/*->/orders/:id", "data-skip" => nil})
    tag = PrivatusAnalytics.tag_string(nonce: "abc123")

    assert tag =~ ~s(data-mask="/orders/*-&gt;/orders/:id")
    assert tag =~ ~s(nonce="abc123")
    refute tag =~ "data-skip"
  end

  test "reads the nonce from the conn assigns" do
    conn = %{assigns: %{csp_nonce: "n1"}, private: %{}}
    assert PrivatusAnalytics.tag_string(conn: conn) =~ ~s(nonce="n1")

    configure(nonce_assign: :my_nonce)
    conn = %{assigns: %{my_nonce: "n2"}, private: %{}}
    assert PrivatusAnalytics.tag_string(conn: conn) =~ ~s(nonce="n2")
  end

  test "prints page props before the tag" do
    html = PrivatusAnalytics.tag_string(props: %{plan: "pro", role: "admin"})

    assert html ==
             ~s|<script>window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>\n| <>
               ~s|<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456" data-props="privatusPageProps"></script>|
  end

  test "empty props print no props script" do
    assert PrivatusAnalytics.tag_string(props: %{}) == @snippet
    assert PrivatusAnalytics.tag_string(props: %{plan: nil}) == @snippet
  end

  test "page props keep numbers, booleans and lists, and get the nonce" do
    html =
      PrivatusAnalytics.tag_string(
        nonce: "abc",
        props: [seats: 3, beta: true, flags: ["a", "b"], ratio: 0.5]
      )

    assert html =~
             ~s|<script nonce="abc">window.privatusPageProps=function(){return {"seats":3,"beta":true,"flags":["a","b"],"ratio":0.5}}</script>|
  end

  test "page props are safe inside a script element" do
    html = PrivatusAnalytics.tag_string(props: %{"Bad Key!" => "</script><b>&\u2028\u2029\"\\"})

    assert html =~ ~S({"bad_key_":"\u003c/script\u003e\u003cb\u003e\u0026\u2028\u2029\"\\"})
    refute html =~ "</script><b>"
  end

  test "page props drop maps, cut long values and keep 30 keys" do
    props =
      for i <- 1..40,
          into: %{},
          do: {"k#{String.pad_leading("#{i}", 2, "0")}", String.duplicate("x", 600)}

    json = PrivatusAnalytics.props_json(Map.put(props, "nested", %{a: 1}))
    decoded = Regex.scan(~r/"k\d+"/, json)

    assert length(decoded) == 30
    refute json =~ "nested"
    assert json =~ ~s("k01":"#{String.duplicate("x", 500)}")
  end

  test "page props from config, the conn and the call merge" do
    configure(props: fn conn -> %{plan: conn.assigns.plan, tier: "a"} end)

    conn =
      %Plug.Conn{assigns: %{plan: "pro"}}
      |> PrivatusAnalytics.put_props(%{role: "admin", tier: "b"})

    html = PrivatusAnalytics.tag_string(conn: conn, props: %{app_version: "1.2"})

    assert html =~ ~s({"plan":"pro","tier":"b","role":"admin","app_version":"1.2"})
  end

  test "page props from an MFA tuple" do
    configure(props: {__MODULE__, :props_for, ["team"]})

    assert PrivatusAnalytics.tag_string() =~ ~s({"role":"team"})
  end

  def props_for(_conn, role), do: %{role: role}

  @stub ~S"""
  <script nonce="abc">window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready'].forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push([m,Array.prototype.slice.call(arguments)])}})</script>
  <script defer
  """

  test "prints the queue stub before the tag" do
    html = PrivatusAnalytics.tag_string(queue_stub: true, nonce: "abc")

    assert html =~ String.trim_trailing(@stub)
    assert {:safe, "<script>window.privatus=" <> _} = PrivatusAnalytics.queue_stub()
  end
end
