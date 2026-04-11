///|
/// Removes leading and trailing Unicode whitespace.
///
/// This filter is intended for pipeline use in templates and mirrors
/// `String::trim`.
pub fn trim(value : String) -> String {
  value.trim().to_string()
}

///|
/// Removes leading Unicode whitespace.
///
/// This filter is intended for pipeline use in templates and mirrors
/// `String::trim_start`.
pub fn trim_start(value : String) -> String {
  value.trim_start().to_string()
}

///|
/// Removes trailing Unicode whitespace.
///
/// This filter is intended for pipeline use in templates and mirrors
/// `String::trim_end`.
pub fn trim_end(value : String) -> String {
  value.trim_end().to_string()
}

///|
/// Converts a string to uppercase using MoonBit's string casing rules.
///
/// The result can be composed with other filters in a template pipeline.
pub fn upper(value : String) -> String {
  value.to_upper()
}

///|
/// Converts a string to lowercase using MoonBit's string casing rules.
///
/// The result can be composed with other filters in a template pipeline.
pub fn lower(value : String) -> String {
  value.to_lower()
}

///|
/// Replaces every occurrence of `old` with `new`.
///
/// The named arguments make generated pipeline calls readable, for example
/// `value |> replace(old=" ", new="-")`.
pub fn replace(value : String, old~ : String, new~ : String) -> String {
  value.replace_all(old~, new~).to_string()
}

///|
/// Returns `fallback` when `value` is empty.
///
/// Non-empty strings are returned unchanged, which makes this a small display
/// helper rather than a general `Option` replacement.
pub fn default(value : String, fallback~ : String) -> String {
  if value.is_empty() {
    fallback
  } else {
    value
  }
}
