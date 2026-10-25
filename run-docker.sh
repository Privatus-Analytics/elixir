#!/bin/sh
# Runs tests, the formatter check, Credo, the docs and the Hex package build in the
# official Elixir image. Usage: ./run-docker.sh
set -e
docker run --rm -v "$PWD":/app -w /app -e MIX_ENV=test elixir:1.17 sh -c 'set -e
  mix local.hex --force >/dev/null && mix local.rebar --force >/dev/null
  mix deps.get
  mix test
  mix format --check-formatted
  mix credo --strict
  MIX_ENV=dev mix deps.get >/dev/null
  MIX_ENV=dev mix docs
  MIX_ENV=dev mix hex.build
  rm -f privatus_analytics-*.tar
'
