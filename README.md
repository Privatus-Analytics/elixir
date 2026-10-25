# Privatus Analytics for Elixir and Phoenix

Adds the cookieless [Privatus Analytics](https://privatusanalytics.com)
tracking script to your Phoenix or Plug app. Use the function component in
your layout, or add a Plug that puts the script in the `<head>` for you.

Privatus Analytics counts visits, sources, pages and conversions without
cookies, local storage or fingerprinting, so analytics does not need a consent
banner by itself. Check with your own counsel for your country.

The package only prints HTML: the browser script and a few HTML attributes. It
never sends events from your server, sets no cookies, and never reads IP
addresses or browser details. You need a Privatus Analytics account to see
reports, and there is a free plan. Sign up at https://privatusanalytics.com.

## Requirements

* Elixir 1.15 or later.
* Phoenix LiveView 1.0 or later for the function component (optional).
* Plug 1.14 or later for the Plug (optional).
* A Privatus Analytics site id (it starts with `pa_`). You find it under
  Site settings, Tracking.

## Install

Add the package to your `mix.exs`:

```elixir
def deps do
  [
    {:privatus_analytics, "~> 1.0"}
  ]
end
```

Then run `mix deps.get`. For the full setup guide and every tracker option,
see the [Privatus Analytics docs](https://privatusanalytics.com/docs).

Set your site id with an environment variable:

```sh
PRIVATUS_SITE_ID=pa_YOURSITEID
```

or in your config (`config/runtime.exs` is a good place):

```elixir
config :privatus_analytics, site_id: "pa_YOURSITEID"
```

The environment variable is read when the page renders, so it works in a
release too.

## Add the tag

Put the component in the `<head>` of your root layout, for example
`lib/my_app_web/components/layouts/root.html.heex`:

```heex
<head>
  <title>My app</title>
  <PrivatusAnalytics.Components.tag />
</head>
```

In production it prints:

```html
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

The tag prints nothing when there is no site id, and nothing outside
production (see below).

Not using HEEx (Phoenix's HTML templates)? In an EEx template, or anywhere
else, use the plain function. `tag/1` returns safe HTML, and `tag_string/1`
returns a plain string:

```eex
<%= PrivatusAnalytics.tag() %>
```

### Content Security Policy nonce

A Content Security Policy (CSP) is a header that tells the browser which
scripts may run. If yours uses a nonce (a random value per request), pass it
in:

```heex
<PrivatusAnalytics.Components.tag nonce={assigns[:csp_nonce]} />
```

You can also pass `conn={@conn}`. The tag then reads the nonce from
`conn.assigns.csp_nonce`. Use `config :privatus_analytics, nonce_assign: :my_nonce`
if your assign has another name.

### Or let the Plug add it

If you would rather not touch your layouts, add the Plug to your browser
pipeline:

```elixir
# lib/my_app_web/router.ex
pipeline :browser do
  # ...
  plug PrivatusAnalytics.Plug
end
```

It adds the tag just before `</head>` in uncompressed `text/html` responses
with status 200. It skips Ajax requests, pages without a `<head>`, and pages
that already have the tag, and it fixes the `content-length` header. It uses
`Plug.Conn.register_before_send/2`, so it works with any Plug app. It reads the
nonce from `conn.assigns.csp_nonce`. Plug options work like the tag options:
`plug PrivatusAnalytics.Plug, modules: ["engage", "auto"]`.

Responses with a `content-encoding` header are left alone. Phoenix and Cowboy
compress after the Plug runs, so this is only a problem if you compress the
body yourself.

## Configuration

Every setting is optional except the site id.

```elixir
# config/config.exs
config :privatus_analytics,
  env: config_env(),
  site_id: "pa_YOURSITEID",                 # or PRIVATUS_SITE_ID
  script_host: "https://privatusstats.com", # or PRIVATUS_SCRIPT_HOST
  modules: ~w(engage auto vitals clicks ask),
  excluded_paths: ~w(/admin/* /preview/*),
  domains: ~w(example.com www.example.com),
  spa: "auto",                              # auto, history, hash or off
  manual: false,                            # true turns off the automatic pageview
  enabled_environments: [:prod],
  extra_attributes: %{"data-mask" => "/orders/*->/orders/:id"}
```

| Setting | Default | What it does |
|---|---|---|
| `site_id` | `PRIVATUS_SITE_ID` | The `data-site` attribute. Nothing prints without it |
| `script_host` | `https://privatusstats.com` | Where `/js/pa.js` is served. Change it only if you host your own copy |
| `modules` | tracker default (`engage`) | The `data-modules` attribute. Setting it replaces the default, so keep `engage` for time on page and scroll depth. `[]` loads none |
| `excluded_paths` | none | The `data-exclude` attribute. Path globs the tracker never counts |
| `domains` | all hosts | The `data-domains` attribute. Count only these hostnames |
| `spa` | `auto` | The `data-spa` attribute (single-page app mode) |
| `manual` | `false` | The `data-manual` attribute |
| `env` | see below | The current environment, for example `config_env()` |
| `enabled_environments` | `[:prod]` | Environments that get the tag |
| `enabled` | not set | `true` or `false` forces the tag on or off in every environment |
| `extra_attributes` | `%{}` | Any other `data-*` attribute |
| `props` | none | Page properties, see [Page properties](#page-properties) |
| `queue_stub` | `false` | `true` prints the queue stub before the tag |
| `nonce_assign` | `:csp_nonce` | The conn assign that holds your CSP nonce |

Each tracker attribute is explained in the [script attributes
reference](https://privatusanalytics.com/docs/tracker/attributes), and the
modules in [Modules](https://privatusanalytics.com/docs/tracker/modules).

You can also override a setting for one page:

```heex
<PrivatusAnalytics.Components.tag modules={["engage", "auto"]} excluded_paths={["/preview/*"]} />
```

### Development and test

Development and test requests are not counted by default, so your own
clicking around never reaches your reports.

The package decides the environment like this:

1. The `env` setting, if you set it. We recommend
   `config :privatus_analytics, env: config_env()` in `config/config.exs`.
2. Otherwise `Mix.env()`, while Mix is running (`mix phx.server`, `mix test`).
3. Otherwise `:prod`. Mix is not part of a release, so a release counts as
   production. If you build a staging release, set `env` (step 1) or
   `enabled: false` so staging is not counted.

To see the tag while you build, set `config :privatus_analytics, enabled: true`
in `config/dev.exs`. The tracker also ignores `localhost` unless you pass
`data-allow-local` or `data-debug` (see [Debug
mode](https://privatusanalytics.com/docs/tracker/debug)):

```elixir
config :privatus_analytics, extra_attributes: %{"data-debug" => "true"}
```

### Leaving people out

Use `data-exclude` through `excluded_paths` for admin areas. To leave out
signed-in staff, render the tag only for everyone else:

```heex
<PrivatusAnalytics.Components.tag :if={!(@current_user && @current_user.admin)} />
```

## Product analytics: see which features people use

You can learn which features people use without any user ids. Tag the
buttons and pages that matter, and Privatus counts them.

A good naming style is "Noun verb", like `Report exported` or `Invite sent`.
Keep the name short and put the details in properties.

### Events on buttons and forms

`event_attrs/2` returns attributes for HEEx. The event is sent when the
element is clicked:

```heex
<button {PrivatusAnalytics.event_attrs("Report exported", format: "csv", source: "toolbar")}>
  Export CSV
</button>
```

It prints:

```html
<button data-privatus-event="Report exported" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar">
```

On a `<form>`, the event is sent when the form is submitted:

```heex
<form action="/invites" method="post" {PrivatusAnalytics.event_attrs("Invite sent", role: "editor")}>
```

In EEx, use `event_attrs_html/2` (safe HTML) or `event_attrs_string/2` (a plain
string):

```eex
<button <%= PrivatusAnalytics.event_attrs_html("Report exported", format: "csv") %>>Export</button>
```

The rules match the tracker. The name is trimmed and cut to 120 characters,
and an empty name prints nothing. Property keys are lowercased, and anything
other than `a-z`, `0-9` and `_` becomes `_`. You can send up to 30
properties. Values become text (lists are joined with commas), `nil` is
dropped, and values are cut to 500 characters. These attributes print even
when the tag is off, so your HTML is the same in development and production.

### Click maps

Give an element a stable name for [click
maps](https://privatusanalytics.com/docs/features/click-maps):

```heex
<a href="/signup" {PrivatusAnalytics.click_attrs("pricing.cta")}>Start free</a>
```

The name can use letters, digits and `_ . : -`, up to 100 characters. Any
other name prints nothing, and a warning is logged outside production. EEx
versions: `click_attrs_html/1` and `click_attrs_string/1`.

### Page properties

Page properties are sent with every pageview and event on the page. Use them
for groups such as plan, role, app version, feature flags or account tier.

```heex
<PrivatusAnalytics.Components.tag props={%{plan: "pro", role: "admin"}} />
```

This prints a small script before the tag, and adds
`data-props="privatusPageProps"` to the tag:

```html
<script>window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>
```

You can also set them in a controller or plug with `put_props/2`. Pass
`conn={@conn}` to the component (the Plug reads the conn by itself):

```elixir
conn |> PrivatusAnalytics.put_props(%{plan: account.plan, role: membership.role})
```

Or set a function in config. It gets the conn (or `nil`) on every request.
Use a `{module, function, args}` tuple so it works in a release config:

```elixir
config :privatus_analytics, props: {MyAppWeb.Analytics, :page_props, []}
```

```elixir
defmodule MyAppWeb.Analytics do
  def page_props(%{assigns: %{current_account: account}}), do: %{plan: account.plan}
  def page_props(_conn), do: %{}
end
```

Config props come first, then `put_props/2`, then the `props` attribute. A
later one wins when two set the same key. Numbers, booleans and lists of text
keep their type. The JSON is escaped so it is safe inside a `<script>`.

**Never put names, emails, user ids or anything else that points to one
person in props.** Privatus counts visitors without any id, so put groups
(plan, role), not people. The server also removes emails and long ids, but do
not rely on that.

### Tracking from your own JavaScript

Call `privatus.track` from your JavaScript:

```js
privatus.track("Feature used", { feature: "export" })
```

The tracker loads with `defer`, so it is not ready for scripts that run
earlier. Add the queue stub, and calls made before the tracker loads are kept
and sent once it arrives:

```heex
<PrivatusAnalytics.Components.tag queue_stub={true} />
```

Or print it alone with `PrivatusAnalytics.queue_stub(nonce: @csp_nonce)`. See the
[JavaScript API docs](https://privatusanalytics.com/docs/tracker/javascript-api).

### LiveView

The root layout renders once, on the first page load. LiveView then moves
between pages with the browser history, and the tracker's `spa` mode counts
those page changes by itself. `event_attrs` and `click_attrs` work on any
LiveView element, including buttons with `phx-click`.

Page properties in the root layout are set on that first load only. If they
change while the LiveView runs, send them from a JavaScript hook with
`privatus.props`, which adds properties to every later pageview and event:

```heex
<div id="privatus-props" phx-hook="PrivatusProps" hidden
     data-privatus-props={PrivatusAnalytics.props_json(%{plan: @plan})}></div>
```

```js
// assets/js/app.js
const Hooks = {
  PrivatusProps: {
    mounted() { this.send() },
    updated() { this.send() },
    send() { window.privatus && window.privatus.props(JSON.parse(this.el.dataset.privatusProps)) }
  },
  TrackOnMount: {
    mounted() { window.privatus && window.privatus.track(this.el.dataset.event) }
  }
}
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })
```

Use the queue stub (`queue_stub={true}`) so these calls are not lost if the
tracker has not loaded yet.

### Where to see it

* [Events](https://privatusanalytics.com/docs/events) lists every event and its properties.
* [Goals](https://privatusanalytics.com/docs/features/goals) turn an event into a conversion.
* [Funnels](https://privatusanalytics.com/docs/features/funnels) show where people drop off between steps.
* [Click maps](https://privatusanalytics.com/docs/features/click-maps) show which named elements get clicked.

## Privacy

The script sets no cookies and stores nothing in the browser. See the
[privacy documentation](https://privatusanalytics.com/docs/privacy) for what is
collected.

## Development

The tests run in Docker so your local Elixir does not matter:

```sh
./run-docker.sh
```

It runs the ExUnit tests, `mix format --check-formatted`, Credo, the docs
build (ExDoc) and `mix hex.build`.

## Contributing

Bug reports and pull requests are welcome at
https://github.com/Privatus-Analytics/elixir.

## License

MIT. See [LICENSE](LICENSE). Privatus Analytics is a product of Two Phase LLC,
Wyoming, USA.
