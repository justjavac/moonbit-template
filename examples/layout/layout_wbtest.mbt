///|
test "render layout with includes" {
  let html = try! render_demo()
  assert_true(html.contains("<title>About &lt;Templates&gt;</title>"))
  assert_true(html.contains("<header>About &lt;Templates&gt;</header>"))
  assert_true(html.contains("<p>Generated pages keep layout code shared.</p>"))
  assert_true(html.contains("<footer>Shared footer</footer>"))
}
