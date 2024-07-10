import gleam/io
import gleam/list
import gleam/regex
import gleam/string

pub type ParserError {
  InvalidRegex(index: Int, re: String)
  EmptySequence(index: Int)
  ExpectedStr(index: Int, expected: String, found: String)
  ExpectedLetters(index: Int)
  UnexpectedEndOfFile
}

pub type Parsed {
  StartOfFile
  Str(String)
  Letters(String)
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
    case string.drop_left(state.target, state.end) {
      "" -> Error(UnexpectedEndOfFile)
      str -> {
        let starts_with = string.starts_with(str, start)

        case starts_with {
          True ->
            Ok(ParserState(
              state.target,
              state.end,
              state.end + string.length(start),
              Str(start),
            ))
          False -> Error(ExpectedStr(state.end, start, str))
        }
      }
    }
  }
}

fn sequence_of_rec(
  parsers: List(Parser),
  state: ParserState,
  results: List(ParserState),
) -> Result(List(ParserState), ParserError) {
  case parsers {
    [] -> Ok(results)
    [first, ..rest] -> {
      let result = first(state)
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

fn letters() -> Parser {
  fn(state: ParserState) {
    let letters_re = "^[A-Za-z]+"

    case regex.from_string(letters_re) {
      Error(_) -> Error(InvalidRegex(state.end, letters_re))
      Ok(re) -> {
        case regex.scan(re, state.target) {
          [] -> Error(ExpectedLetters(state.end))
          [match, ..] -> {
            Ok(ParserState(
              state.target,
              state.end,
              state.end + string.length(match.content),
              Letters(match.content),
            ))
          }
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
  let parser =
    sequence_of([letters(), str(": "), str("hello"), str(" "), str("world")])
  run(parser, target)
}

pub fn main() {
  let parsed = parse("message: hello world")
  io.debug(parsed)
}
