///|
/// Values that can render themselves to HTML strings.
///
/// Generated template implementations use this trait so callers can render
/// pages with `page.render()`. The method allows `raise` because template code
/// can call ordinary MoonBit functions that use checked errors. User-defined
/// page structs normally receive their implementation from `template_codegen`.
pub(open) trait Render {
  render(Self) -> String raise
}

///|
/// Error values reserved for render-time failures.
///
/// The current generator mostly reports parse and codegen problems before
/// rendering, but this error type gives runtime integrations a stable place for
/// checked failures such as invalid dynamic includes.
pub(all) suberror RenderError {
  Message(String)
  InvalidInclude(String)
} derive(Eq, Debug)

///|
/// HTML that has already been validated by the caller.
///
/// `SafeHtml` is the trust boundary for raw output. Generated templates escape
/// ordinary values by default; wrapping a string in this type documents that the
/// caller intentionally wants the markup written without escaping.
pub struct SafeHtml {
  value : String
}

///|
/// Wraps trusted HTML so it can be passed through raw template output.
///
/// Prefer constructing this value near the code that validates or produces the
/// markup, so the trust decision remains visible at the call site.
pub fn SafeHtml::new(value : String) -> SafeHtml {
  SafeHtml::{ value, }
}

///|
/// Returns the trusted HTML payload without escaping it.
///
/// This is useful when adapting `SafeHtml` to another renderer or writing tests
/// that need to inspect the exact trusted markup.
pub fn SafeHtml::to_string(self : SafeHtml) -> String {
  self.value
}

///|
/// Creates a trusted HTML wrapper.
///
/// This convenience constructor is equivalent to `SafeHtml::new(value)` and is
/// exported for template-facing code that prefers function-style helpers.
pub fn safe_html(value : String) -> SafeHtml {
  SafeHtml::new(value)
}

///|
/// Writes trusted HTML as-is when interpolated or rendered as a raw value.
pub impl Show for SafeHtml with output(self, logger) {
  logger.write_string(self.value)
}

///|
/// Formats a value the same way MoonBit string interpolation does.
///
/// Generated templates call this for expression output before applying the
/// escaped or raw write path, so any type with a `Show` implementation can be
/// rendered consistently.
pub fn[T : Show] render_value(value : T) -> String {
  "\{value}"
}

///|
/// Escapes the HTML-sensitive characters `&`, `<`, `>`, `"`, and `'`.
///
/// The returned string is safe to place in normal HTML text positions produced
/// by templates. Raw output must be requested explicitly through template syntax
/// or by rendering trusted `SafeHtml`.
pub fn escape_html(value : String) -> String {
  let out = StringBuilder::new()
  for ch in value {
    match ch {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '"' => out.write_string("&quot;")
      '\'' => out.write_string("&#39;")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}

///|
/// Writes raw text into a template output buffer without escaping it.
///
/// Generated renderers use this path for trusted content and raw template
/// expressions. Prefer `write_escaped` for ordinary user-provided strings.
pub fn write_raw(out : StringBuilder, value : String) -> Unit {
  out.write_string(value)
}

///|
/// Escapes text and writes it into a template output buffer.
///
/// This is the default output path for generated escaped expressions such as
/// `<%= value %>`.
pub fn write_escaped(out : StringBuilder, value : String) -> Unit {
  out.write_string(escape_html(value))
}
