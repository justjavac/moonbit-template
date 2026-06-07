///|
/// Minimal page type used to test the render trait contract.
struct TinyPage {
  title : String
}

///|
/// Renders `TinyPage` as a small HTML fragment for runtime tests.
impl @template.Render for TinyPage with fn render(self) {
  "<h1>\{self.title}</h1>"
}

///|
test "escape html special characters" {
  inspect(
    @template.escape_html("<a href=\"/x?y=1&z='2'\">Hi</a>"),
    content="&lt;a href=&quot;/x?y=1&amp;z=&#39;2&#39;&quot;&gt;Hi&lt;/a&gt;",
  )
}

///|
test "safe html renders raw" {
  let html = @template.safe_html("<strong>Ada</strong>")
  inspect(@template.render_value(html), content="<strong>Ada</strong>")
  inspect(html.to_string(), content="<strong>Ada</strong>")
}

///|
test "render value uses interpolation semantics" {
  inspect(@template.render_value("MoonBit"), content="MoonBit")
}

///|
test "write helpers append raw and escaped text" {
  let out = StringBuilder::new()
  @template.write_raw(out, "<p>")
  @template.write_escaped(out, "Ada & Bob")
  @template.write_raw(out, "</p>")
  inspect(out.to_string(), content="<p>Ada &amp; Bob</p>")
}

///|
test "render trait propagates checked style" {
  let page = TinyPage::{ title: "Hello" }
  inspect(try! page.render(), content="<h1>Hello</h1>")
}
