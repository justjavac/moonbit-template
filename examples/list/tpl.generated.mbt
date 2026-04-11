// Generated using `template_codegen`, DON'T EDIT IT

///|
/// Generated render implementation for templates/list.mtpl.
pub impl @template.Render for TodoListPage with render(self) {
  let out = StringBuilder::new()
  out.write_string("<section class=\"todo-list\">\n  <h1>")
  out.write_string(@template.escape_html(@template.render_value(self.list.title |> @template.trim)))
  out.write_string("</h1>\n\n  ")
  if self.list.items.length() == 0 {
  out.write_string("\n    <p>No items yet.</p>\n  ")
  } else {
  out.write_string("\n    <ul>\n    ")
  for item in self.list.items {
  out.write_string("\n      ")
  if item.done {
  out.write_string("\n        <li class=\"done\">")
  out.write_string(@template.escape_html(@template.render_value(item.title)))
  out.write_string("</li>\n      ")
  } else {
  out.write_string("\n        <li>")
  out.write_string(@template.escape_html(@template.render_value(item.title)))
  out.write_string("</li>\n      ")
  }
  out.write_string("\n    ")
  }
  out.write_string("\n    </ul>\n  ")
  }
  out.write_string("\n</section>\n")
  out.to_string()
}
