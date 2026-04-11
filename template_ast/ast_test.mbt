///|
test "construct ast nodes" {
  let start = @template_ast.pos(offset=0, line=1, column=1)
  let end = @template_ast.pos(offset=7, line=1, column=8)
  let span = @template_ast.span(file="hello.mtpl", start~, end~)
  let nodes = [
    @template_ast.text_node("Hello ", span),
    @template_ast.escaped_expr_node("self.name", span),
  ]
  json_inspect(@template_ast.template(path="hello.mtpl", nodes~), content={
    "path": "hello.mtpl",
    "nodes": [
      [
        "Text",
        {
          "text": "Hello ",
          "span": {
            "file": "hello.mtpl",
            "start": { "offset": 0, "line": 1, "column": 1 },
            "end": { "offset": 7, "line": 1, "column": 8 },
          },
        },
      ],
      [
        "EscapedExpr",
        {
          "expr": "self.name",
          "span": {
            "file": "hello.mtpl",
            "start": { "offset": 0, "line": 1, "column": 1 },
            "end": { "offset": 7, "line": 1, "column": 8 },
          },
        },
      ],
    ],
  })
}
