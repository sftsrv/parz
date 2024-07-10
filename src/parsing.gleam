import gleam/io
import gleam/list
import gleam/string

pub type ParserError {
  EmptySequence(index: Int)
  ExpectedStr(index: Int, expected: String, found: String)
}

pub type Parsed {
  StartOfFile
  Str(String)
  Sequence(List(ParserState))
}

pub type ParserState {
  ParserState(target: String, start: Int, end: Int, result: Parsed)
}

/// A Parser is defined as a function that takes in a ParserState and returns a
/// ParserState or an Error
type Parser =
  fn(ParserState) -> Result(ParserState, ParserError)

fn str(start: String) -> Parser {
  fn(state: ParserState) {
    let from_str = string.drop_left(state.target, state.end)
    let starts_with = string.starts_with(from_str, start)

    case starts_with {
      True ->
        Ok(ParserState(
          state.target,
          state.end,
          state.end + string.length(start),
          Str(start),
        ))
      False -> Error(ExpectedStr(state.end, start, from_str))
    }
  }
}

fn sequence_of_rec(
  parsers: List(Parser),
  last_state: ParserState,
  results: List(ParserState),
) -> Result(List(ParserState), ParserError) {
  case parsers {
    [] -> Ok(results)
    [first, ..rest] -> {
      let result = first(last_state)
      case result {
        Error(err) -> Error(err)
        Ok(ok) -> {
          let recurse = sequence_of_rec(rest, ok, results)

          case recurse {
            Error(err) -> Error(err)
            Ok(rec) -> Ok([ok, ..rec])
          }
        }
      }
    }
  }
}

fn sequence_of(parsers: List(Parser)) -> Parser {
  fn(state: ParserState) {
    let result = sequence_of_rec(parsers, state, [])

    case result {
      Error(err) -> Error(err)
      Ok(ok) -> {
        let empty_error = Error(EmptySequence(state.end))

        case list.last(ok) {
          Error(_) -> empty_error
          Ok(last) ->
            Ok(ParserState(last.target, state.end, last.end, Sequence(ok)))
        }
      }
    }
  }
}

fn run(parser, target) {
  let initial = ParserState(target, 0, 0, StartOfFile)
  parser(initial)
}

fn parse(target) {
  let parser = sequence_of([str("hello"), str(" "), str("world")])
  run(parser, target)
}

pub fn main() {
  let parsed = parse("hello world")
  io.debug(parsed)
}
