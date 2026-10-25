# Changelog

## 1.0.0 - 2026-10-25

- Initial release.
- `<PrivatusAnalytics.Components.tag />` function component, plus `tag/1` and `tag_string/1` for EEx.
- `PrivatusAnalytics.Plug` that adds the tag to the head of HTML responses.
- Settings for site id, script host, modules, excluded paths, single-page app mode and more.
- Page properties (`props`, `put_props/2`, config function) and the optional queue stub.
- `event_attrs/2` and `click_attrs/1` helpers, with `_html` and `_string` versions.
- Prints the tag only in production by default.
- When the tag is off (disabled, outside production or no site id) and `queue_stub` is on,
  the tag prints only the queue stub, so `privatus.track` calls never fail. No tracker and
  no page props script print then, and a props function is not called.
- `PrivatusAnalytics.Plug` inserts nothing when the tag is off.
- Add the conformance example app in `example/` (Phoenix with HEEx).
- README: a privacy policy paragraph you can paste.
