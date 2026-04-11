# justjavac/template_codegen/parser

Parses template text into the shared AST.

```mbt check
///|
test {
  let template = try! @parser.parse("hello.mtpl", "Hi <%= self.name %>")
  inspect(template.nodes.length(), content="2")
}
```
