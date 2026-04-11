///|
test "render filters example" {
  let html = try! render_demo()
  assert_true(html.contains("<h1>MOONBIT TEMPLATES</h1>"))
  assert_true(html.contains("<p>untitled</p>"))
  assert_true(html.contains("<code>moonbit-templates</code>"))
}
