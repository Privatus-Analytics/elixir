# Conformance example app (Phoenix with HEEx). Build with the package folder
# as the context: docker build -f example/Dockerfile .
FROM elixir:1.17-slim
ENV MIX_ENV=prod LANG=C.UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
  && mix local.hex --force && mix local.rebar --force
# The package from this repo's own source (a path dependency), not from Hex.
WORKDIR /pkg
COPY mix.exs .formatter.exs README.md CHANGELOG.md LICENSE ./
COPY lib/ lib/
COPY example/ example/
WORKDIR /pkg/example
RUN mix deps.get --only prod && mix compile
EXPOSE 8080
CMD ["mix", "phx.server"]
