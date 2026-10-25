defmodule PrivatusAnalytics.ConfigTest do
  use PrivatusAnalytics.Case, async: false

  alias PrivatusAnalytics.Config

  test "site id is nil by default" do
    assert Config.site_id() == nil
  end

  test "site id falls back to the environment variable" do
    System.put_env("PRIVATUS_SITE_ID", "pa_FROMENV123")

    assert Config.site_id() == "pa_FROMENV123"
  end

  test "an explicit site id wins over the environment variable" do
    System.put_env("PRIVATUS_SITE_ID", "pa_FROMENV123")
    configure(site_id: "pa_EXPLICIT01")

    assert Config.site_id() == "pa_EXPLICIT01"
  end

  test "a blank site id counts as missing" do
    configure(site_id: "  ")

    assert Config.site_id() == nil
  end

  test "script host defaults, reads the environment and drops a trailing slash" do
    assert Config.script_host() == "https://privatusstats.com"
    System.put_env("PRIVATUS_SCRIPT_HOST", "https://env.example.com/")
    assert Config.script_host() == "https://env.example.com"
    configure(script_host: "https://stats.example.com/")

    assert Config.script_host() == "https://stats.example.com"
  end

  test "only production is enabled by default" do
    assert Config.enabled?(env: :prod)
    refute Config.enabled?(env: :dev)
    refute Config.enabled?(env: :test)
  end

  test "Mix.env is used when no env is set" do
    assert Config.env() == :test
    refute Config.enabled?()
  end

  test "the env setting wins over Mix.env" do
    configure(env: :prod)

    assert Config.env() == :prod
    assert Config.enabled?()
  end

  test "enabled environments can be changed" do
    configure(enabled_environments: [:prod, :staging])

    assert Config.enabled?(env: :staging)
    assert Config.enabled?(env: "staging")
  end

  test "enabled forces the tag on or off" do
    configure(enabled: true)
    assert Config.enabled?(env: :dev)
    configure(enabled: false)

    refute Config.enabled?(env: :prod)
  end
end
