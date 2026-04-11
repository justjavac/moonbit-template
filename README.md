# justjavac/template

[![template coverage](https://codecov.io/gh/justjavac/moonbit-template/branch/main/graph/badge.svg?component=template)](https://codecov.io/gh/justjavac/moonbit-template)
[![template_ast coverage](https://codecov.io/gh/justjavac/moonbit-template/branch/main/graph/badge.svg?component=template_ast)](https://codecov.io/gh/justjavac/moonbit-template)
[![template_parser coverage](https://codecov.io/gh/justjavac/moonbit-template/branch/main/graph/badge.svg?component=template_parser)](https://codecov.io/gh/justjavac/moonbit-template)
[![template_codegen coverage](https://codecov.io/gh/justjavac/moonbit-template/branch/main/graph/badge.svg?component=template_codegen)](https://codecov.io/gh/justjavac/moonbit-template)

`justjavac/template` is a precompiled template engine for MoonBit.

## Quick Start

Then define data in ordinary MoonBit source:

```moonbit
#tpl.path("templates/profile_card.mtpl")
pub(all) struct ProfileCard {
  name : String
  bio : @template.SafeHtml
}
```

Write the template:

```html
<article>
  <h1><%= name |> trim |> upper %></h1>
  <%- bio %>
</article>
```

Generate the renderer:

```bash
moon install justjavac/template_codegen
```

For normal package builds, wire the same command into `pre-build`:

```moonbit
options(
  "pre-build": [
    {
      "input": [
        "main.mbt",
        "templates/profile_card.mtpl",
        "templates/partials/footer.mtpl",
      ],
      "output": "tpl.generated.mbt",
      "command": "template_codegen --scan $input -o $output",
    },
  ],
)
```

The generated source implements `@template.Render` for `ProfileCard`, so callers
use the method form:

```moonbit
let page = ProfileCard::{
  name: " justjavac ",
  bio: @template.safe_html("<p>Trusted HTML</p>"),
}
let html = try! page.render()
```

## Modules

- `justjavac/template`: runtime `Render`, escaping, safe HTML, formatting, render errors, and filters.
- `justjavac/template_ast`: shared AST and source location model.
- `justjavac/template_parser`: Sailfish-like tag parser with embedded MoonBit snippets.
- `justjavac/template_codegen`: MoonBit source generation and the installable `template_codegen` CLI.
- `justjavac/template_examples`: example packages and tests.

The important rule is dependency direction: generated templates should depend
only on `justjavac/template`, not on parser, codegen, or AST modules.

## Template Syntax

```moonbit
#tpl.path("templates/profile_card.mtpl")
pub(all) struct ProfileCard {
  user : User
  title : String
  items : Array[Item]
  trusted_html : @template.SafeHtml
}
```

```html
<h1><%= title %></h1>
<p><%- trusted_html %></p>

<% if user.is_admin() { %>
  <a href="/admin">Admin</a>
<% } else { %>
  <span>Member</span>
<% } %>

<ul>
<% for item in items { %>
  <li><%= item.name |> trim |> upper %></li>
<% } %>
</ul>

<%~ "footer.mtpl" %>
```

## Filters

Template filters are ordinary MoonBit functions exposed by
`justjavac/template`. The template parser does not invent a custom pipeline
language. Instead, codegen rewrites short names on the right side of `|>`:

```html
<%= title |> trim |> upper %>
```

Generated form:

```moonbit
@template.escape_html(
  @template.render_value(self.title |> @template.trim |> @template.upper),
)
```

Built-in filters currently include `trim`, `trim_start`, `trim_end`, `upper`,
`lower`, `replace`, and `default`.

## Examples

Runnable example packages live under [`examples`](examples):

- [`examples/hello`](examples/hello): escaped output, raw `SafeHtml`, conditionals, and include.
- [`examples/list`](examples/list): loops plus empty/non-empty branches.
- [`examples/layout`](examples/layout): static includes sharing the current `self`.
- [`examples/filter_pipelines`](examples/filter_pipelines): short filter pipelines and labeled filter arguments.

Run them with:

```bash
moon -C examples run hello
moon -C examples run list
moon -C examples run layout
moon -C examples run filter_pipelines
```

## License

This project is licensed under MIT.
