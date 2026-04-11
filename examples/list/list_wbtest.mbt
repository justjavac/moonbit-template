///|
test "render todo list" {
  let html = try! render_demo()
  assert_true(html.contains("<h1>Release checklist</h1>"))
  assert_true(html.contains("class=\"done\""))
  assert_true(html.contains("ship examples"))
}

///|
test "render empty todo list" {
  let html = try! empty_page().render()
  assert_true(html.contains("<p>No items yet.</p>"))
}
