[
  import_deps: [:phoenix_live_view, :plug],
  locals_without_parens: [attr: 2, attr: 3],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"]
]
