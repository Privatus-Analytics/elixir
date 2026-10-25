defmodule PrivatusAnalytics.AttrsTest do
  use PrivatusAnalytics.Case, async: false

  import ExUnit.CaptureLog

  test "event attributes as pairs" do
    assert PrivatusAnalytics.event_attrs("Export CSV", format: "csv", source: "toolbar") == [
             {"data-privatus-event", "Export CSV"},
             {"data-privatus-prop-format", "csv"},
             {"data-privatus-prop-source", "toolbar"}
           ]
  end

  test "event attributes as a string and safe HTML" do
    expected =
      ~s(data-privatus-event="Export CSV" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar")

    assert PrivatusAnalytics.event_attrs_string("Export CSV", %{format: "csv", source: "toolbar"}) ==
             expected

    assert PrivatusAnalytics.event_attrs_html("Export CSV", format: "csv", source: "toolbar") ==
             {:safe, expected}
  end

  test "the event name is trimmed and cut to 120 characters" do
    [{_, name}] = PrivatusAnalytics.event_attrs("  " <> String.duplicate("é", 130) <> " ")

    assert String.length(name) == 120
  end

  test "an empty event name renders nothing" do
    assert PrivatusAnalytics.event_attrs("  ", plan: "pro") == []
    assert PrivatusAnalytics.event_attrs_string(nil) == ""
  end

  test "prop keys are cleaned and cut" do
    long = String.duplicate("a", 70)
    attrs = PrivatusAnalytics.event_attrs("Signup", %{"Plan Type" => "pro", long => "x"})

    assert {"data-privatus-prop-plan_type", "pro"} in attrs
    assert {"data-privatus-prop-" <> String.duplicate("a", 64), "x"} in attrs
  end

  test "prop values become strings, nil is dropped and values are cut" do
    attrs =
      PrivatusAnalytics.event_attrs("Signup",
        yes: true,
        no: false,
        seats: 3,
        ratio: 1.5,
        tags: ["a", "b"],
        gone: nil,
        nested: %{a: 1},
        long: String.duplicate("x", 600)
      )

    assert attrs == [
             {"data-privatus-event", "Signup"},
             {"data-privatus-prop-yes", "true"},
             {"data-privatus-prop-no", "false"},
             {"data-privatus-prop-seats", "3"},
             {"data-privatus-prop-ratio", "1.5"},
             {"data-privatus-prop-tags", "a,b"},
             {"data-privatus-prop-long", String.duplicate("x", 500)}
           ]
  end

  test "at most 30 props" do
    props = for i <- 1..40, do: {"p#{i}", "v"}

    assert length(PrivatusAnalytics.event_attrs("Many", props)) == 31
  end

  test "event attribute values are escaped" do
    assert PrivatusAnalytics.event_attrs_string(~s(Say "hi" <b>), q: "a&b") ==
             ~s(data-privatus-event="Say &quot;hi&quot; &lt;b&gt;" data-privatus-prop-q="a&amp;b")
  end

  test "event attributes render even when the tag is off" do
    configure(enabled: false)

    assert PrivatusAnalytics.event_attrs("Signup") == [{"data-privatus-event", "Signup"}]
  end

  test "click attributes" do
    assert PrivatusAnalytics.click_attrs("pricing.cta") == [
             {"data-privatus-click", "pricing.cta"}
           ]

    assert PrivatusAnalytics.click_attrs_string("nav:sign-up_2") ==
             ~s(data-privatus-click="nav:sign-up_2")

    assert PrivatusAnalytics.click_attrs_html("a") == {:safe, ~s(data-privatus-click="a")}
  end

  test "an invalid click name renders nothing and warns outside production" do
    log =
      capture_log(fn ->
        assert PrivatusAnalytics.click_attrs("has space") == []
        assert PrivatusAnalytics.click_attrs("") == []
        assert PrivatusAnalytics.click_attrs(String.duplicate("a", 101)) == []
      end)

    assert log =~ "ignored"
  end

  test "props_json cleans like the tag" do
    assert PrivatusAnalytics.props_json(%{"Plan" => "pro", seats: 2, gone: nil}) ==
             ~s({"plan":"pro","seats":2})
  end
end
