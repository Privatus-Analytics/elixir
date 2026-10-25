import Config

config :phoenix, :json_library, Jason
config :logger, level: :info

config :example, Example.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  server: true,
  # Only signs cookies, and this app sets none. Not a real secret.
  secret_key_base: String.duplicate("conformance-example-", 4)

# Forced on, so the tag prints whatever the environment. The site id and
# script host come from PRIVATUS_SITE_ID and PRIVATUS_SCRIPT_HOST.
config :privatus_analytics, enabled: true
