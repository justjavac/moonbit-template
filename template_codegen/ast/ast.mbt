///|
/// A 1-based source position plus the underlying string offset.
///
/// `offset` is the raw string offset used by scanners, while `line` and
/// `column` are intended for human-readable diagnostics.
pub(all) struct SourcePos {
  offset : Int
  line : Int
  column : Int
} derive(Eq, ToJson, Debug)

///|
/// Creates a source position for diagnostics and source spans.
pub fn pos(offset~ : Int, line~ : Int, column~ : Int) -> SourcePos {
  { offset, line, column }
}

///|
/// A half-open source span in one file.
///
/// The `start` position points at the first character in the range and `end`
/// points just after the range. This keeps parser and codegen diagnostics easy
/// to map back to the original template or MoonBit source.
pub(all) struct SourceSpan {
  file : String
  start : SourcePos
  end : SourcePos
} derive(Eq, ToJson, Debug)

///|
/// Creates a half-open source span for a single file.
pub fn span(file~ : String, start~ : SourcePos, end~ : SourcePos) -> SourceSpan {
  { file, start, end }
}

///|
/// One parsed template item.
///
/// Nodes preserve source spans so downstream tools can report precise errors.
/// Escaped expressions correspond to `<%= ... %>`, raw expressions correspond
/// to `<%- ... %>`, statements correspond to `<% ... %>`, includes correspond
/// to `<%~ "path" %>`, and comments correspond to `<%# ... %>`.
pub(all) enum TemplateNode {
  Text(text~ : String, span~ : SourceSpan)
  EscapedExpr(expr~ : String, span~ : SourceSpan)
  RawExpr(expr~ : String, span~ : SourceSpan)
  Statement(code~ : String, span~ : SourceSpan)
  Include(path~ : String, span~ : SourceSpan)
  Comment(text~ : String, span~ : SourceSpan)
} derive(Eq, ToJson, Debug)

///|
/// Creates a plain text node.
///
/// Text nodes are emitted directly as string writes by the generator.
pub fn text_node(text : String, span : SourceSpan) -> TemplateNode {
  Text(text~, span~)
}

///|
/// Creates an escaped expression output node.
///
/// Generated renderers evaluate the expression, format it with `Show`, and
/// HTML-escape the formatted value before writing it.
pub fn escaped_expr_node(expr : String, span : SourceSpan) -> TemplateNode {
  EscapedExpr(expr~, span~)
}

///|
/// Creates a raw expression output node.
///
/// Generated renderers evaluate the expression and write the formatted value
/// without HTML escaping, so callers should use it only for trusted content.
pub fn raw_expr_node(expr : String, span : SourceSpan) -> TemplateNode {
  RawExpr(expr~, span~)
}

///|
/// Creates a MoonBit statement node.
///
/// Statement nodes are copied into the generated renderer after template field
/// references and short filters have been qualified by codegen.
pub fn statement_node(code : String, span : SourceSpan) -> TemplateNode {
  Statement(code~, span~)
}

///|
/// Creates a static include node.
///
/// File-based codegen expands include nodes before emitting MoonBit source.
pub fn include_node(path : String, span : SourceSpan) -> TemplateNode {
  Include(path~, span~)
}

///|
/// Creates a template comment node.
///
/// Comments are preserved in the AST for tooling, but they do not emit output.
pub fn comment_node(text : String, span : SourceSpan) -> TemplateNode {
  Comment(text~, span~)
}

///|
/// A parsed template document.
///
/// `path` identifies the source template for diagnostics, and `nodes` stores
/// the parsed items in render order.
pub(all) struct Template {
  path : String
  nodes : Array[TemplateNode]
} derive(Eq, ToJson, Debug)

///|
/// Creates a parsed template document from a path and node sequence.
pub fn template(path~ : String, nodes~ : Array[TemplateNode]) -> Template {
  { path, nodes }
}

///|
/// A user struct bound to a template path by `#tpl.path`.
///
/// Codegen uses the binding to connect a MoonBit struct with a template file.
/// `field_names` records the struct fields that may be referenced without
/// `self.` inside templates; generated code prefixes them automatically.
pub(all) struct TemplateBinding {
  source_path : String
  template_path : String
  struct_name : String
  field_names : Array[String]
  span : SourceSpan
} derive(Eq, ToJson, Debug)

///|
/// Creates a template binding discovered in MoonBit source.
///
/// This constructor is useful for tests and custom scanners that want to feed
/// bindings into the code generator without parsing files again.
pub fn template_binding(
  source_path~ : String,
  template_path~ : String,
  struct_name~ : String,
  field_names? : Array[String] = [],
  span~ : SourceSpan,
) -> TemplateBinding {
  { source_path, template_path, struct_name, field_names, span }
}
