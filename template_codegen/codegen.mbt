///|
/// Errors raised by the code generator.
///
/// `InvalidArguments` reports CLI misuse, `InvalidBinding` reports malformed
/// `#tpl.path` source bindings, `MissingTemplate` reports files that cannot be
/// found, and `UnexpandedInclude` protects in-memory generation from emitting a
/// renderer that still contains static include nodes.
pub(all) suberror CodegenError {
  InvalidArguments(String)
  InvalidBinding(source_path~ : String, offset~ : Int, message~ : String)
  MissingTemplate(String)
  UnexpandedInclude(path~ : String)
} derive(Eq, Debug)

///|
/// A source binding plus its loaded template content.
///
/// `source_path`, `template_path`, and `struct_name` identify the source
/// binding. `field_names` is used to rewrite bare template field references to
/// `self.<field>`, and `content` stores the template text after any static
/// includes have been expanded.
pub(all) struct TemplateInput {
  source_path : String
  template_path : String
  struct_name : String
  field_names : Array[String]
  content : String
} derive(Eq, ToJson, Debug)

///|
/// Creates an in-memory generation input.
///
/// Use this constructor when tests or custom tools already have template text
/// available. Pass `field_names` when template expressions omit `self.` for
/// fields declared on the bound struct.
pub fn template_input(
  source_path~ : String,
  template_path~ : String,
  struct_name~ : String,
  field_names? : Array[String] = [],
  content~ : String,
) -> TemplateInput {
  TemplateInput::{
    source_path,
    template_path,
    struct_name,
    field_names,
    content,
  }
}

///|
/// Scans MoonBit source for `#tpl.path("...")` bindings.
///
/// Each binding records the template path and the following struct name. This
/// scanner intentionally handles only the small attribute/struct shape needed by
/// codegen; MoonBit syntax and type checking remain the compiler's job. Field
/// names from the struct body are collected so generated template code can add
/// `self.` automatically where needed.
pub fn scan_source(
  source_path : String,
  source : String,
) -> Array[@ast.TemplateBinding] raise CodegenError {
  let bindings : Array[@ast.TemplateBinding] = []
  let marker = "#tpl.path("
  let len = source.length()
  for offset = 0; offset < len; {
    let rest = source.unsafe_substring(start=offset, end=len)
    match rest.find(marker) {
      None => continue len
      Some(relative_marker) => {
        let attr_start = offset + relative_marker
        let path_start = attr_start + marker.length()
        match read_quoted_string(source, path_start) {
          None =>
            raise CodegenError::InvalidBinding(
              source_path~,
              offset=attr_start,
              message="expected quoted template path",
            )
          Some((template_path, after_path)) => {
            let after_attr = skip_ws(source, after_path)
            if after_attr >= len ||
              source.unsafe_substring(start=after_attr, end=after_attr + 1) !=
              ")" {
              raise CodegenError::InvalidBinding(
                source_path~,
                offset=after_attr,
                message="expected closing ')' after template path",
              )
            }
            let search_start = after_attr + 1
            match find_struct_name(source, search_start) {
              None =>
                raise CodegenError::InvalidBinding(
                  source_path~,
                  offset=search_start,
                  message="expected struct after #tpl.path",
                )
              Some((struct_name, after_name, _struct_start)) => {
                let field_names = read_struct_fields(source, _struct_start)
                let span = @ast.span(
                  file=source_path,
                  start=position_at(source, attr_start),
                  end=position_at(source, after_name),
                )
                bindings.push(
                  @ast.template_binding(
                    source_path~,
                    template_path~,
                    struct_name~,
                    field_names~,
                    span~,
                  ),
                )
                continue after_name
              }
            }
          }
        }
      }
    }
  } nobreak {
    bindings
  }
}

///|
/// Generates a complete MoonBit source file from loaded template inputs.
///
/// The returned source contains one `Render` implementation per input. Package
/// imports are not emitted; callers should import `justjavac/template` in the
/// target package's `moon.pkg`.
pub fn generate(inputs : Array[TemplateInput]) -> String raise {
  let out = StringBuilder::new()
  out.write_string("// Generated using `template_codegen`, DON'T EDIT IT\n")
  for input in inputs {
    out.write_string("\n")
    out.write_string(generate_one(input))
  }
  out.to_string()
}

///|
/// Generates one `Render` implementation from an in-memory template.
///
/// This function is useful for tests and tools that already loaded template
/// text. Static include nodes must be expanded before calling it; otherwise it
/// raises `CodegenError::UnexpandedInclude`.
pub fn generate_one(input : TemplateInput) -> String raise {
  let template = @parser.parse(input.template_path, input.content)
  let out = StringBuilder::new()
  out.write_string("///|\n")
  out.write_string("/// Generated render implementation for ")
  out.write_string(input.template_path)
  out.write_string(".\n")
  out.write_string("pub impl @template.Render for ")
  out.write_string(input.struct_name)
  out.write_string(" with render(self) {\n")
  out.write_string("  let out = StringBuilder::new()\n")
  write_nodes(out, template.nodes, input.field_names)
  out.write_string("  out.to_string()\n")
  out.write_string("}\n")
  out.to_string()
}

///|
/// Generates `output_path` by scanning source files and reading their templates.
///
/// Only `.mbt` inputs are scanned, and the output path is ignored if it appears
/// in the input list. Template paths are resolved relative to the source file
/// that owns the `#tpl.path` attribute, and static includes are expanded before
/// source generation.
pub fn generate_from_files(
  source_files : Array[String],
  output_path : String,
) -> Unit raise {
  let inputs : Array[TemplateInput] = []
  for source_path in source_files {
    if source_path == output_path || !source_path.has_suffix(".mbt") {
      continue
    }
    let source = @fs.read_file_to_string(source_path)
    let bindings = scan_source(source_path, source)
    for binding in bindings {
      let template_path = resolve_template_path(
        binding.source_path,
        binding.template_path,
      )
      if !@fs.path_exists(template_path) {
        raise CodegenError::MissingTemplate(template_path)
      }
      let content = read_template_with_includes(template_path)
      inputs.push(
        template_input(
          source_path=binding.source_path,
          template_path=binding.template_path,
          struct_name=binding.struct_name,
          field_names=binding.field_names,
          content~,
        ),
      )
    }
  }
  @fs.write_string_to_file(output_path, generate(inputs))
}

///|
/// Parses command line arguments and runs file-based generation.
///
/// The supported CLI shape is `template_codegen --scan <inputs...> -o <output>`.
/// Extra non-scan arguments are ignored so the first executable path from
/// `@env.args()` can be passed directly.
pub fn run_cli(args : Array[String]) -> Unit raise {
  let parsed = parse_args(args)
  generate_from_files(parsed.scan_files, parsed.output_path)
}

///|
/// Parsed command line options for the codegen executable.
priv struct CliOptions {
  scan_files : Array[String]
  output_path : String
}

///|
/// Parses `template_codegen --scan <inputs...> -o <output>`.
fn parse_args(args : Array[String]) -> CliOptions raise CodegenError {
  let scan_files : Array[String] = []
  let mut output_path = ""
  let mut scanning = false
  let len = args.length()
  let mut index = 0
  while index < len {
    let arg = args[index]
    if arg == "--scan" {
      scanning = true
    } else if arg == "-o" || arg == "--output" {
      if index + 1 >= len {
        raise CodegenError::InvalidArguments("expected output path after -o")
      }
      output_path = args[index + 1]
      scanning = false
      index = index + 1
    } else if scanning {
      scan_files.push(arg)
    }
    index = index + 1
  }
  if output_path.is_empty() {
    raise CodegenError::InvalidArguments("missing -o <output>")
  }
  CliOptions::{ scan_files, output_path }
}

///|
/// Emits MoonBit statements for parsed template nodes.
fn write_nodes(
  out : StringBuilder,
  nodes : Array[@ast.TemplateNode],
  field_names : Array[String],
) -> Unit raise CodegenError {
  for node in nodes {
    match node {
      Text(text~, ..) => write_text_statement(out, text)
      EscapedExpr(expr~, ..) => {
        let qualified = qualify_template_code(expr, field_names)
        out.write_string(
          "  out.write_string(@template.escape_html(@template.render_value(",
        )
        out.write_string(qualified)
        out.write_string(")))\n")
      }
      RawExpr(expr~, ..) => {
        let qualified = qualify_template_code(expr, field_names)
        out.write_string("  out.write_string(@template.render_value(")
        out.write_string(qualified)
        out.write_string("))\n")
      }
      Statement(code~, ..) =>
        if !code.is_empty() {
          out.write_string("  ")
          out.write_string(qualify_template_code(code, field_names))
          out.write_string("\n")
        }
      Include(path~, ..) => raise CodegenError::UnexpandedInclude(path~)
      Comment(_) => ()
    }
  }
}

///|
/// Emits a string literal write for non-empty text.
fn write_text_statement(out : StringBuilder, text : String) -> Unit {
  if !text.is_empty() {
    out.write_string("  out.write_string(")
    out.write_string(moon_string_literal(text))
    out.write_string(")\n")
  }
}

///|
/// Returns a MoonBit string literal for generated source.
fn moon_string_literal(value : String) -> String {
  let out = StringBuilder::new()
  out.write_char('"')
  for ch in value {
    match ch {
      '\\' => out.write_string("\\\\")
      '"' => out.write_string("\\\"")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(ch)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
/// Prefixes template struct fields with `self.` and qualifies short filters.
///
/// The transformation is intentionally small and template-oriented: it skips
/// quoted strings, leaves already-qualified values alone, avoids field labels,
/// and then rewrites short pipeline filters such as `title |> trim` to
/// `title |> @template.trim`.
pub fn qualify_template_code(
  expr : String,
  field_names : Array[String],
) -> String {
  prefix_self_fields(expr, field_names) |> qualify_filters
}

///|
/// Qualifies short pipeline filters as calls to `@template`.
///
/// Already-qualified calls such as `value |> @custom.filter` are preserved.
/// Bare identifiers after `|>` are treated as runtime filters so generated
/// packages only need an explicit dependency on `justjavac/template`.
pub fn qualify_filters(expr : String) -> String {
  let out = StringBuilder::new()
  let len = expr.length()
  for offset = 0; offset < len; {
    let rest = expr.unsafe_substring(start=offset, end=len)
    match rest.find("|>") {
      None => {
        out.write_string(rest)
        continue len
      }
      Some(relative_pipe) => {
        let pipe = offset + relative_pipe
        out.write_string(expr.unsafe_substring(start=offset, end=pipe + 2))
        let after_space = copy_ws(expr, pipe + 2, out)
        if after_space < len &&
          expr.unsafe_substring(start=after_space, end=after_space + 1) == "@" {
          continue after_space
        } else {
          match expr.get_char(after_space) {
            Some(ch) if is_ident_start(ch) => {
              let ident_end = take_ident(expr, after_space)
              let ident = expr.unsafe_substring(
                start=after_space,
                end=ident_end,
              )
              out.write_string("@template.")
              out.write_string(ident)
              continue ident_end
            }
            _ => continue after_space
          }
        }
      }
    }
  } nobreak {
    out.to_string()
  }
}

///|
/// Prefixes bare template field names with `self.`.
fn prefix_self_fields(code : String, field_names : Array[String]) -> String {
  if field_names.is_empty() {
    return code
  }
  let out = StringBuilder::new()
  let len = code.length()
  for offset = 0; offset < len; {
    match code.get_char(offset) {
      Some('"') => continue copy_quoted_literal(code, offset, '"', out)
      Some('\'') => continue copy_quoted_literal(code, offset, '\'', out)
      Some(ch) if is_ident_start(ch) => {
        let ident_end = take_ident(code, offset)
        let ident = code.unsafe_substring(start=offset, end=ident_end)
        if should_prefix_field(code, offset, ident_end, ident, field_names) {
          out.write_string("self.")
        }
        out.write_string(ident)
        continue ident_end
      }
      Some(ch) => {
        out.write_char(ch)
        continue offset + 1
      }
      None => continue len
    }
  } nobreak {
    out.to_string()
  }
}

///|
/// Returns whether an identifier should be rewritten as a template field.
fn should_prefix_field(
  code : String,
  start : Int,
  end : Int,
  ident : String,
  field_names : Array[String],
) -> Bool {
  if !field_names.contains(ident) {
    return false
  }
  if start > 0 {
    match code.get_char(start - 1) {
      Some('.' | '@') => return false
      Some(ch) if is_ident_continue(ch) => return false
      _ => ()
    }
  }
  let next = skip_ws(code, end)
  if next < code.length() {
    match code.get_char(next) {
      Some(':' | '=') => return false
      _ => ()
    }
  }
  true
}

///|
/// Copies a quoted literal without rewriting identifiers inside it.
fn copy_quoted_literal(
  source : String,
  offset : Int,
  quote : Char,
  out : StringBuilder,
) -> Int {
  let len = source.length()
  out.write_char(quote)
  let mut current = offset + 1
  while current < len {
    match source.get_char(current) {
      Some('\\') => {
        out.write_char('\\')
        if current + 1 < len {
          match source.get_char(current + 1) {
            Some(ch) => out.write_char(ch)
            None => ()
          }
        }
        current = current + 2
      }
      Some(ch) => {
        out.write_char(ch)
        current = current + 1
        if ch == quote {
          return current
        }
      }
      None => return current
    }
  }
  current
}

///|
/// Copies whitespace from `offset` into `out` and returns the first non-space offset.
fn copy_ws(source : String, offset : Int, out : StringBuilder) -> Int {
  let len = source.length()
  let mut current = offset
  while current < len {
    match source.get_char(current) {
      Some(ch) if ch == ' ' || ch == '\n' || ch == '\t' || ch == '\r' => {
        out.write_char(ch)
        current = current + 1
      }
      _ => return current
    }
  }
  len
}

///|
/// Reads a quoted string starting at `offset`.
fn read_quoted_string(source : String, offset : Int) -> (String, Int)? {
  let len = source.length()
  let start = skip_ws(source, offset)
  if start >= len || source.unsafe_substring(start~, end=start + 1) != "\"" {
    return None
  }
  let mut current = start + 1
  while current < len {
    match source.get_char(current) {
      Some('"') =>
        return Some(
          (source.unsafe_substring(start=start + 1, end=current), current + 1),
        )
      Some('\\') => current = current + 2
      Some(_) => current = current + 1
      None => return None
    }
  }
  None
}

///|
/// Locates the struct name following an attribute.
fn find_struct_name(source : String, offset : Int) -> (String, Int, Int)? {
  let len = source.length()
  let rest = source.unsafe_substring(start=offset, end=len)
  match rest.find("struct") {
    None => None
    Some(relative_struct) => {
      let struct_start = offset + relative_struct
      let name_start = skip_ws(source, struct_start + "struct".length())
      if name_start >= len {
        None
      } else {
        match source.get_char(name_start) {
          Some(ch) if is_ident_start(ch) => {
            let name_end = take_ident(source, name_start)
            Some(
              (
                source.unsafe_substring(start=name_start, end=name_end),
                name_end,
                struct_start,
              ),
            )
          }
          _ => None
        }
      }
    }
  }
}

///|
/// Reads field names from a struct declaration for implicit `self.` rewriting.
fn read_struct_fields(source : String, struct_start : Int) -> Array[String] {
  let fields : Array[String] = []
  match find_char_from(source, struct_start, '{') {
    None => fields
    Some(open) => {
      let close = find_matching_brace(source, open)
      let mut offset = open + 1
      while offset < close {
        match source.get_char(offset) {
          Some(ch) if is_ident_start(ch) => {
            let ident_end = take_ident(source, offset)
            let after_ident = skip_ws(source, ident_end)
            if after_ident < close &&
              source.unsafe_substring(start=after_ident, end=after_ident + 1) ==
              ":" {
              fields.push(source.unsafe_substring(start=offset, end=ident_end))
            }
            offset = ident_end
          }
          Some(_) => offset = offset + 1
          None => offset = close
        }
      }
      fields
    }
  }
}

///|
/// Finds the first target character at or after `offset`.
fn find_char_from(source : String, offset : Int, target : Char) -> Int? {
  let len = source.length()
  let mut current = offset
  while current < len {
    match source.get_char(current) {
      Some(ch) if ch == target => return Some(current)
      Some(_) => current = current + 1
      None => return None
    }
  }
  None
}

///|
/// Finds the closing brace that matches an opening brace.
fn find_matching_brace(source : String, open : Int) -> Int {
  let len = source.length()
  let mut depth = 0
  let mut current = open
  while current < len {
    match source.get_char(current) {
      Some('{') => depth = depth + 1
      Some('}') => {
        depth = depth - 1
        if depth == 0 {
          return current
        }
      }
      _ => ()
    }
    current = current + 1
  }
  len
}

///|
/// Skips ASCII whitespace.
fn skip_ws(source : String, offset : Int) -> Int {
  let len = source.length()
  let mut current = offset
  while current < len {
    match source.get_char(current) {
      Some(' ' | '\n' | '\t' | '\r') => current = current + 1
      _ => return current
    }
  }
  len
}

///|
/// Returns the end offset of an identifier.
fn take_ident(source : String, offset : Int) -> Int {
  let len = source.length()
  let mut current = offset
  while current < len {
    match source.get_char(current) {
      Some(ch) if is_ident_continue(ch) => current = current + 1
      _ => return current
    }
  }
  len
}

///|
/// Tests whether a character can begin a MoonBit identifier in this scanner.
fn is_ident_start(ch : Char) -> Bool {
  ch == '_' || ('a' <= ch && ch <= 'z') || ('A' <= ch && ch <= 'Z')
}

///|
/// Tests whether a character can continue a MoonBit identifier in this scanner.
fn is_ident_continue(ch : Char) -> Bool {
  is_ident_start(ch) || ('0' <= ch && ch <= '9')
}

///|
/// Resolves an attribute template path relative to its source file.
fn resolve_template_path(
  source_path : String,
  template_path : String,
) -> String {
  join_path(dirname_path(source_path), template_path)
}

///|
/// Reads a template file and expands static include tags recursively.
fn read_template_with_includes(template_path : String) -> String raise {
  let source = @fs.read_file_to_string(template_path)
  let template = @parser.parse(template_path, source)
  let out = StringBuilder::new()
  let base = dirname_path(template_path)
  for node in template.nodes {
    match node {
      Include(path~, ..) => {
        let include_path = join_path(base, path)
        out.write_string(read_template_with_includes(include_path))
      }
      Text(text~, ..) => out.write_string(text)
      EscapedExpr(expr~, ..) => {
        out.write_string("<%= ")
        out.write_string(expr)
        out.write_string(" %>")
      }
      RawExpr(expr~, ..) => {
        out.write_string("<%- ")
        out.write_string(expr)
        out.write_string(" %>")
      }
      Statement(code~, ..) => {
        out.write_string("<% ")
        out.write_string(code)
        out.write_string(" %>")
      }
      Comment(text~, ..) => {
        out.write_string("<%# ")
        out.write_string(text)
        out.write_string(" %>")
      }
    }
  }
  out.to_string()
}

///|
/// Returns the directory part of a path using either slash style.
fn dirname_path(path : String) -> String {
  let mut last_sep = -1
  for index, ch in path {
    if ch == '/' || ch == '\\' {
      last_sep = index
    }
  }
  if last_sep < 0 {
    "."
  } else if last_sep == 0 {
    path.unsafe_substring(start=0, end=1)
  } else {
    path.unsafe_substring(start=0, end=last_sep)
  }
}

///|
/// Joins a base directory and a relative path using `/`.
fn join_path(base : String, child : String) -> String {
  if child.has_prefix("/") ||
    child.has_prefix("\\") ||
    (child.length() > 1 && child.unsafe_substring(start=1, end=2) == ":") {
    child
  } else if base == "." || base.is_empty() {
    child
  } else if base.has_suffix("/") || base.has_suffix("\\") {
    base + child
  } else {
    base + "/" + child
  }
}

///|
/// Computes a 1-based source position for scanner diagnostics.
fn position_at(source : String, offset : Int) -> @ast.SourcePos {
  let prefix = source.unsafe_substring(start=0, end=offset)
  let mut line = 1
  let mut column = 1
  for ch in prefix {
    if ch == '\n' {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
  }
  @ast.pos(offset~, line~, column~)
}
