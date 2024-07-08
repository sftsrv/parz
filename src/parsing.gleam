import gleam/io
import gleam/string

pub type ParserError {
  ExpectedStr(index: Int, expected: String, found: String)
}

pub type Parsed {
  StartOfFile
  Str(str: String)
}

pub type ParserState {
  ParserState(target: String, index: Int, result: Parsed)
}

fn str(start: String) {
  fn(state: ParserState) {
    let from_str = state.target |> string.drop_left(state.index)
    let starts_with = string.starts_with(from_str, state.target)

    case starts_with {
      True ->
        Ok(ParserState(
          state.target,
          state.index + string.length(start),
          Str(start),
        ))
      False -> Error(ExpectedStr(state.index, start, from_str))
    }
  }
}

fn run(parser, target) {
  let initial = ParserState(target, 0, StartOfFile)
  parser(initial)
}

fn parse(target) {
  let parser = str("hello")
  run(parser, target)
}

pub fn main() {
  let parsed = parse("hello world")
  io.debug(parsed)
}
