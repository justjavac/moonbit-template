///|
test "string filters compose in pipelines" {
  inspect(" Ada " |> @template.trim |> @template.upper, content="ADA")
  inspect("MoonBit" |> @template.lower, content="moonbit")
  inspect("  left" |> @template.trim_start, content="left")
  inspect("right  " |> @template.trim_end, content="right")
}

///|
test "replace and default filters" {
  inspect(
    @template.replace("hello moon", old="moon", new="template"),
    content="hello template",
  )
  inspect(@template.default("", fallback="Untitled"), content="Untitled")
  inspect(@template.default("Named", fallback="Untitled"), content="Named")
}
