# justjavac/template

`justjavac/template` is a precompiled template engine for MoonBit.

## Quick Start

Then define data in ordinary MoonBit source:

```moonbit nocheck
///|
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
moonx justjavac/template_codegen --scan main.mbt templates/profile_card.mtpl -o tpl.generated.mbt
```

For normal package builds, wire the same command into `pre-build`:

```moonbit nocheck
options(
  "pre-build": [
    {
      "input": [
        "main.mbt",
        "templates/profile_card.mtpl",
        "templates/partials/footer.mtpl",
      ],
      "output": "tpl.generated.mbt",
      "command": "moonx justjavac/template_codegen@0.1.4 --scan $input -o $output",
    },
  ],
)
```

The generated source implements `@template.Render` for `ProfileCard`, so callers
use the method form:

```moonbit nocheck
///|
let page = ProfileCard::{
  name: " justjavac ",
  bio: @template.safe_html("<p>Trusted HTML</p>"),
}

///|
let html = try! page.render()
```
