///|
/// Errors reported while scanning template tags.
///
/// `UnclosedTag` points at a `<%` tag without a matching `%>`, and
/// `InvalidInclude` reports include tags that do not contain a static quoted
/// path. The parser keeps these errors small so callers can format diagnostics
/// for their own tools.
pub(all) suberror ParseError {
  UnclosedTag(path~ : String, offset~ : Int)
  InvalidInclude(path~ : String, offset~ : Int, content~ : String)
} derive(Eq, Debug)

///|
/// Parses Sailfish/EJS-style template tags into a template AST.
///
/// The parser recognizes text, escaped expressions, raw expressions,
/// statements, comments, and static includes. It preserves file/line/column
/// spans for every node and leaves embedded MoonBit syntax checking to the
/// generated source and MoonBit compiler.
pub fn parse(path : String, source : String) -> @ast.Template raise ParseError {
  let nodes : Array[@ast.TemplateNode] = []
  let len = source.length()
  for offset = 0; offset < len; {
    let rest = source.unsafe_substring(start=offset, end=len)
    match rest.find("<%") {
      None => {
        push_text(nodes, path, source, offset, len)
        continue len
      }
      Some(relative_open) => {
        let open = offset + relative_open
        push_text(nodes, path, source, offset, open)
        let body_start = open + 2
        let after_open = source.unsafe_substring(start=body_start, end=len)
        match after_open.find("%>") {
          None => raise ParseError::UnclosedTag(path~, offset=open)
          Some(relative_close) => {
            let close = body_start + relative_close
            let body = source.unsafe_substring(start=body_start, end=close)
            nodes.push(parse_tag(path, source, body, open, close + 2))
            continue close + 2
          }
        }
      }
    }
  } nobreak {
    @ast.template(path~, nodes~)
  }
}

///|
/// Appends non-empty text ranges to the node list.
fn push_text(
  nodes : Array[@ast.TemplateNode],
  path : String,
  source : String,
  start : Int,
  end : Int,
) -> Unit {
  if start < end {
    let text = source.unsafe_substring(start~, end~)
    nodes.push(@ast.text_node(text, source_span(path, source, start, end)))
  }
}

///|
/// Parses the content between `<%` and `%>`.
fn parse_tag(
  path : String,
  source : String,
  body : String,
  start : Int,
  end : Int,
) -> @ast.TemplateNode raise ParseError {
  let span = source_span(path, source, start, end)
  if body.has_prefix("=") {
    let expr = body
      .unsafe_substring(start=1, end=body.length())
      .trim()
      .to_string()
    @ast.escaped_expr_node(expr, span)
  } else if body.has_prefix("-") {
    let expr = body
      .unsafe_substring(start=1, end=body.length())
      .trim()
      .to_string()
    @ast.raw_expr_node(expr, span)
  } else if body.has_prefix("#") {
    let text = body
      .unsafe_substring(start=1, end=body.length())
      .trim()
      .to_string()
    @ast.comment_node(text, span)
  } else if body.has_prefix("~") {
    let include_content = body
      .unsafe_substring(start=1, end=body.length())
      .trim()
      .to_string()
    match parse_include_path(include_content) {
      Some(include_path) => @ast.include_node(include_path, span)
      None =>
        raise ParseError::InvalidInclude(
          path~,
          offset=start,
          content=include_content,
        )
    }
  } else {
    @ast.statement_node(body.trim().to_string(), span)
  }
}

///|
/// Extracts the static string path from an include tag body.
fn parse_include_path(content : String) -> String? {
  let len = content.length()
  if len >= 2 && content.has_prefix("\"") && content.has_suffix("\"") {
    Some(content.unsafe_substring(start=1, end=len - 1))
  } else {
    None
  }
}

///|
/// Builds a span for a range in the source string.
fn source_span(
  path : String,
  source : String,
  start : Int,
  end : Int,
) -> @ast.SourceSpan {
  @ast.span(
    file=path,
    start=position_at(source, start),
    end=position_at(source, end),
  )
}

///|
/// Computes a 1-based line and column for a string offset.
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
