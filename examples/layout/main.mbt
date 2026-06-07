///|
/// Page data rendered by the layout/include example.
///
/// The bound template pulls in shared header and footer partials, escapes
/// `title`, and renders `body` as trusted HTML.
#tpl.path("templates/page.mtpl")
pub(all) struct LayoutPage {
  title : String
  body : @template.SafeHtml
}

///|
/// Builds the sample page used by the layout example and its tests.
///
/// `body` is trusted HTML so the template can demonstrate raw output inside a
/// shared layout.
pub fn sample_page() -> LayoutPage {
  {
    title: "About <Templates>",
    body: @template.safe_html("<p>Generated pages keep layout code shared.</p>"),
  }
}

///|
/// Renders the layout example with static includes expanded by codegen.
///
/// `main` prints this value, and tests call it directly.
pub fn render_demo() -> String raise {
  sample_page().render()
}

///|
/// Runs the layout/include example.
fn main {
  println(try! render_demo())
}
