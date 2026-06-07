///|
/// Page data rendered by the filter-pipeline example.
///
/// The template applies string filters to these fields to demonstrate that
/// short filter names are rewritten to the runtime facade during codegen.
#tpl.path("templates/filters.mtpl")
pub(all) struct FiltersPage {
  title : String
  slug : String
  summary : String
}

///|
/// Builds the sample page used by the filter-pipeline example.
///
/// Empty `summary` demonstrates the `default` filter in the template.
pub fn sample_page() -> FiltersPage {
  { title: " moonbit templates ", slug: "MoonBit Templates", summary: "" }
}

///|
/// Renders the filter-pipeline example.
///
/// `main` prints this value, and tests call it directly.
pub fn render_demo() -> String raise {
  sample_page().render()
}

///|
/// Runs the filter-pipeline example.
fn main {
  println(try! render_demo())
}
