///|
fn[T, E : Error] try_result_codegen_wbtest(f : () -> T raise E) -> Result[T, E] {
  try f() catch {
    e => Err(e)
  } noraise {
    value => Ok(value)
  }
}

///|
test "scan source bindings" {
  let source =
    #|#tpl.path("templates/profile_card.mtpl")
    #|pub(all) struct ProfileCard {
    #|  name : String
    #|}
    #|
  let bindings = try! scan_source("main.mbt", source)
  json_inspect(bindings, content=[
    {
      "source_path": "main.mbt",
      "template_path": "templates/profile_card.mtpl",
      "struct_name": "ProfileCard",
      "field_names": ["name"],
      "span": {
        "file": "main.mbt",
        "start": { "offset": 0, "line": 1, "column": 1 },
        "end": { "offset": 68, "line": 2, "column": 28 },
      },
    },
  ])
}

///|
test "qualify pipeline filters" {
  inspect(
    qualify_filters("self.user.name |> trim |> upper"),
    content="self.user.name |> @template.trim |> @template.upper",
  )
  inspect(
    qualify_template_code("user.name |> trim |> upper", ["user"]),
    content="self.user.name |> @template.trim |> @template.upper",
  )
  inspect(
    qualify_template_code("if user.is_admin() {", ["user"]),
    content="if self.user.is_admin() {",
  )
  inspect(
    qualify_filters("self.name |> @template.trim"),
    content="self.name |> @template.trim",
  )
  inspect(
    qualify_filters("self.name |> (fn(x) { x })"),
    content="self.name |> (fn(x) { x })",
  )
}

///|
test "generate render implementation" {
  let input = template_input(
    source_path="main.mbt",
    template_path="templates/profile_card.mtpl",
    struct_name="ProfileCard",
    field_names=["name", "bio"],
    content="<article>\n<% let visible = true %><%# hidden %><h1><%= name |> trim |> upper %></h1><%- bio %></article>",
  )
  inspect(
    try! generate([input]),
    content=(
      #|// Generated using `template_codegen`, DON'T EDIT IT
      #|
      #|///|
      #|/// Generated render implementation for templates/profile_card.mtpl.
      #|pub impl @template.Render for ProfileCard with render(self) {
      #|  let out = StringBuilder::new()
      #|  out.write_string("<article>\n")
      #|  let visible = true
      #|  out.write_string("<h1>")
      #|  out.write_string(@template.escape_html(@template.render_value(self.name |> @template.trim |> @template.upper)))
      #|  out.write_string("</h1>")
      #|  out.write_string(@template.render_value(self.bio))
      #|  out.write_string("</article>")
      #|  out.to_string()
      #|}
      #|
    ),
  )
}

///|
test "scan source binding errors" {
  let unquoted = try_result_codegen_wbtest(() => {
    scan_source("bad.mbt", "#tpl.path(nope)")
  })
  guard unquoted
    is Err(InvalidBinding(message="expected quoted template path", ..)) else {
    fail("expected quoted path error")
  }

  let missing_close = try_result_codegen_wbtest(() => {
    scan_source("bad.mbt", "#tpl.path(\"x\"")
  })
  guard missing_close
    is Err(
      InvalidBinding(message="expected closing ')' after template path", ..)
    ) else {
    fail("expected closing paren error")
  }

  let missing_struct = try_result_codegen_wbtest(() => {
    scan_source("bad.mbt", "#tpl.path(\"x\")\nlet x = 1")
  })
  guard missing_struct
    is Err(InvalidBinding(message="expected struct after #tpl.path", ..)) else {
    fail("expected missing struct error")
  }

  let no_name = try_result_codegen_wbtest(() => {
    scan_source("bad.mbt", "#tpl.path(\"x\")\nstruct")
  })
  guard no_name
    is Err(InvalidBinding(message="expected struct after #tpl.path", ..)) else {
    fail("expected missing struct name error")
  }

  let bad_name = try_result_codegen_wbtest(() => {
    scan_source("bad.mbt", "#tpl.path(\"x\")\nstruct 123")
  })
  guard bad_name
    is Err(InvalidBinding(message="expected struct after #tpl.path", ..)) else {
    fail("expected bad struct name error")
  }

  let escaped_path = try! scan_source(
    "ok.mbt", "#tpl.path(\"templates/quoted\\\"path.mtpl\")\nstruct EscapedPath {}",
  )
  inspect(escaped_path.length(), content="1")
}

///|
test "generate escapes text literals and rejects unexpanded include" {
  let input = template_input(
    source_path="main.mbt",
    template_path="templates/text.mtpl",
    struct_name="TextPage",
    content="a\\b\t\"quoted\"",
  )
  inspect(
    try! generate([input]).contains("a\\\\b\\t\\\"quoted\\\""),
    content="true",
  )

  let with_include = template_input(
    source_path="main.mbt",
    template_path="templates/include.mtpl",
    struct_name="IncludePage",
    content="<%~ \"footer.mtpl\" %>",
  )
  let result = try_result_codegen_wbtest(() => generate_one(with_include))
  guard result is Err(UnexpandedInclude(path="footer.mtpl")) else {
    fail("expected unexpanded include error")
  }
}

///|
test "generate from files expands includes" {
  let dir = "_build/template_codegen_test"
  if !@fs.path_exists(dir) {
    try! @fs.create_dir(dir)
  }
  let source_path = dir + "/page.mbt"
  let template_path = dir + "/page.mtpl"
  let include_path = dir + "/footer.mtpl"
  let output_path = dir + "/tpl.generated.mbt"
  @fs.write_string_to_file(
    source_path, "#tpl.path(\"page.mtpl\")\npub(all) struct FilePage { title : String }\n",
  )
  @fs.write_string_to_file(
    template_path, "<% let raw = title %><%# keep this hidden %><h1><%= title %></h1><%- raw %><%~ \"footer.mtpl\" %>",
  )
  @fs.write_string_to_file(include_path, "<footer>Done</footer>")
  try! generate_from_files([source_path, output_path], output_path)
  let generated = try! @fs.read_file_to_string(output_path)
  assert_true(generated.contains("FilePage"))
  assert_true(generated.contains("<footer>Done</footer>"))

  let output_path2 = dir + "/tpl2.generated.mbt"
  try! run_cli(["template_codegen", "--scan", source_path, "-o", output_path2])
  assert_true((try! @fs.read_file_to_string(output_path2)).contains("FilePage"))
}

///|
test "run cli reports argument errors" {
  let missing_value = try_result_codegen_wbtest(() => {
    run_cli(["template_codegen", "-o"])
  })
  guard missing_value is Err(InvalidArguments("expected output path after -o")) else {
    fail("expected missing output value error")
  }

  let missing_output = try_result_codegen_wbtest(() => {
    run_cli(["template_codegen", "--scan"])
  })
  guard missing_output is Err(InvalidArguments("missing -o <output>")) else {
    fail("expected missing output error")
  }
}

///|
test "generate from files reports missing template" {
  let dir = "_build/template_codegen_missing_test"
  if !@fs.path_exists(dir) {
    try! @fs.create_dir(dir)
  }
  let source_path = dir + "/missing.mbt"
  @fs.write_string_to_file(
    source_path, "#tpl.path(\"missing.mtpl\")\npub(all) struct MissingPage {}\n",
  )
  let result = try_result_codegen_wbtest(() => {
    generate_from_files([source_path], dir + "/tpl.generated.mbt")
  })
  guard result is Err(MissingTemplate(_)) else {
    fail("expected MissingTemplate")
  }
}
