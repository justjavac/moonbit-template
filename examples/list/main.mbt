///|
/// A single todo item rendered by the list example.
///
/// `title` is escaped by the template, and `done` controls whether the item is
/// displayed as completed.
pub(all) struct TodoItem {
  title : String
  done : Bool
}

///|
/// Todo list data passed into the page template.
///
/// The list template uses `title` as a heading and iterates over `items` to
/// demonstrate MoonBit statements embedded in template files.
pub(all) struct TodoList {
  title : String
  items : Array[TodoItem]
}

///|
/// Data model bound to `templates/list.mtpl`.
///
/// Keeping the page wrapper separate from `TodoList` mirrors the shape used by
/// applications that pass view-specific state into a generated renderer.
#tpl.path("templates/list.mtpl")
pub(all) struct TodoListPage {
  list : TodoList
}

///|
/// Builds the populated todo-list page used by the runnable example.
///
/// The values are intentionally stable so tests can assert the rendered output.
pub fn sample_page() -> TodoListPage {
  {
    list: {
      title: " Release checklist ",
      items: [
        { title: "write docs", done: true },
        { title: "ship examples", done: false },
      ],
    },
  }
}

///|
/// Builds an empty todo-list page for tests of the fallback branch.
///
/// This keeps the empty-state scenario easy to exercise without duplicating
/// setup code in each test.
pub fn empty_page() -> TodoListPage {
  { list: { title: "Empty", items: [] } }
}

///|
/// Renders the populated todo-list example.
///
/// `main` prints this value, and tests call it directly.
pub fn render_demo() -> String raise {
  sample_page().render()
}

///|
/// Runs the todo-list example.
fn main {
  println(try! render_demo())
}
