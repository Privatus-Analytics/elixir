import Config

# Bandit gzips responses by default, so Content-Length would be the gzip size.
# The conformance suite compares it with the unzipped body, so turn that off.
config :example, Example.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT", "8080")),
    http_options: [compress: false]
  ]
