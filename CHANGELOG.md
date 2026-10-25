# Changelog

## 1.0.0 - 2026-10-25

- Initial release.
- `<PrivatusAnalytics.Components.tag />` function component, plus `tag/1` and `tag_string/1` for EEx.
- `PrivatusAnalytics.Plug` that adds the tag to the head of HTML responses.
- Settings for site id, script host, modules, excluded paths, single-page app mode and more.
- Page properties (`props`, `put_props/2`, config function) and the optional queue stub.
- `event_attrs/2` and `click_attrs/1` helpers, with `_html` and `_string` versions.
- Prints the tag only in production by default.
