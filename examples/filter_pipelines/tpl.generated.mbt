// Generated using `template_codegen`, DON'T EDIT IT

///|
/// Generated render implementation for templates/filters.mtpl.
pub impl @template.Render for FiltersPage with render(self) {
  let out = StringBuilder::new()
  out.write_string("<article class=\"filters\">\n  <h1>")
  out.write_string(@template.escape_html(@template.render_value(self.title |> @template.trim |> @template.upper)))
  out.write_string("</h1>\n  <p>")
  out.write_string(@template.escape_html(@template.render_value(self.summary |> @template.default(fallback="Untitled") |> @template.lower)))
  out.write_string("</p>\n  <code>")
  out.write_string(@template.escape_html(@template.render_value(self.slug |> @template.trim |> @template.lower |> @template.replace(old=" ", new="-"))))
  out.write_string("</code>\n</article>\n")
  out.to_string()
}
