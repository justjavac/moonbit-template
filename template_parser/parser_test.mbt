///|
test "parse template tags" {
  let source = "<h1><%= title |> trim %></h1><%# hidden %><%- body %>"
  let template = try! @template_parser.parse("page.mtpl", source)
  json_inspect(template.nodes, content=[
    [
      "Text",
      {
        "text": "<h1>",
        "span": {
          "file": "page.mtpl",
          "start": { "offset": 0, "line": 1, "column": 1 },
          "end": { "offset": 4, "line": 1, "column": 5 },
        },
      },
    ],
    [
      "EscapedExpr",
      {
        "expr": "title |> trim",
        "span": {
          "file": "page.mtpl",
          "start": { "offset": 4, "line": 1, "column": 5 },
          "end": { "offset": 24, "line": 1, "column": 25 },
        },
      },
    ],
    [
      "Text",
      {
        "text": "</h1>",
        "span": {
          "file": "page.mtpl",
          "start": { "offset": 24, "line": 1, "column": 25 },
          "end": { "offset": 29, "line": 1, "column": 30 },
        },
      },
    ],
    [
      "Comment",
      {
        "text": "hidden",
        "span": {
          "file": "page.mtpl",
          "start": { "offset": 29, "line": 1, "column": 30 },
          "end": { "offset": 42, "line": 1, "column": 43 },
        },
      },
    ],
    [
      "RawExpr",
      {
        "expr": "body",
        "span": {
          "file": "page.mtpl",
          "start": { "offset": 42, "line": 1, "column": 43 },
          "end": { "offset": 53, "line": 1, "column": 54 },
        },
      },
    ],
  ])
}

///|
test "parse include and statements" {
  let source = "<% if ok { %>\nok\n<% } %><%~ \"partials/footer.mtpl\" %>"
  let template = try! @template_parser.parse("page.mtpl", source)
  inspect(
    template.nodes.length(),
    content=(
      #|4
    ),
  )
  json_inspect(template.nodes[3], content=[
    "Include",
    {
      "path": "partials/footer.mtpl",
      "span": {
        "file": "page.mtpl",
        "start": { "offset": 24, "line": 3, "column": 8 },
        "end": { "offset": 53, "line": 3, "column": 37 },
      },
    },
  ])
}

///|
test "invalid include reports an error" {
  let result = try? @template_parser.parse("bad.mtpl", "<%~ footer %>")
  guard result
    is Err(InvalidInclude(path="bad.mtpl", offset=0, content="footer")) else {
    fail("expected InvalidInclude")
  }
}

///|
test "unclosed tag reports an error" {
  let result = try? @template_parser.parse("bad.mtpl", "hello <% if true {")
  guard result is Err(UnclosedTag(path="bad.mtpl", offset=6)) else {
    fail("expected UnclosedTag")
  }
}
