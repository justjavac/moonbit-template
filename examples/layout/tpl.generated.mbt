// Generated using `template_codegen`, DON'T EDIT IT

///|
/// Generated render implementation for templates/page.mtpl.
pub impl @template.Render for LayoutPage with render(self) {
  let out = StringBuilder::new()
  out.write_string("<!doctype html>\n<html>\n  <head>\n  <title>")
  out.write_string(@template.escape_html(@template.render_value(self.title)))
  out.write_string("</title>\n</head>\n\n  <body>\n    <header>")
  out.write_string(@template.escape_html(@template.render_value(self.title)))
  out.write_string("</header>\n\n    <main>")
  out.write_string(@template.render_value(self.body))
  out.write_string("</main>\n    <footer>Shared footer</footer>\n\n  </body>\n</html>\n")
  out.to_string()
}
