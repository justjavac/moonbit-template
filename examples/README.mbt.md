# justjavac/template examples

Runnable example packages for the precompiled template workflow:

- `hello`: escaped output, raw safe HTML, a condition, and an include.
- `list`: loops plus empty/non-empty branches.
- `layout`: static includes that share the current template scope.
- `filter_pipelines`: short pipeline filters expanded to `@template`.

Each example package includes a `pre-build` rule that regenerates
`tpl.generated.mbt` from its `#tpl.path` bindings and templates.

```bash
moon -C examples run hello
moon -C examples run list
moon -C examples run layout
moon -C examples run filter_pipelines
```
