///|
/// User data rendered by the profile-card example.
///
/// The template reads `name` for escaped text output and calls `is_admin` to
/// choose between the admin and member branches.
pub(all) struct User {
  name : String
  admin : Bool
}

///|
/// Returns whether the user should render the admin branch.
///
/// The template calls this method directly from a conditional statement.
pub fn User::is_admin(self : User) -> Bool {
  self.admin
}

///|
/// Data model bound to `templates/profile_card.mtpl`.
///
/// `bio` is wrapped in `@template.SafeHtml` because the template renders it with
/// raw output after the caller has already decided the markup is trusted.
#tpl.path("templates/profile_card.mtpl")
pub(all) struct ProfileCard {
  user : User
  bio : @template.SafeHtml
}

///|
/// Renders the profile-card example with stable sample data.
///
/// Tests call this helper directly, while `main` prints the same rendered page
/// for users running the example from the command line.
pub fn render_demo() -> String raise {
  let user = User::{ name: " Ada ", admin: true }
  let page = ProfileCard::{
    user,
    bio: @template.safe_html("<p>Loves analytical engines.</p>"),
  }
  page.render()
}

///|
/// Runs the profile-card example.
fn main {
  println(try! render_demo())
}
