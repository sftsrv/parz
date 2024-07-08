import gleam/io
import gleam/list
import gleam/string

pub type ParserError {
  BadSequence(index: Int)
  EmptySequence(index: Int)
  ExpectedStr(index: Int, expected: String, found: String)
}

pub type Parsed {
  StartOfFile
  Str(String)
  Sequence(List(Result(Parsed, ParserError)))
}

pub type ParserState {
  ParserState(target: String, index: Int, result: Parsed)
}

/// A Parser is defined as a function that takes in a ParserState and returns a
/// ParserState or an Error
type Parser =
  fn(ParserState) -> Result(ParserState, ParserError)

fn str(start: String) -> Parser {
  fn(state: ParserState) {
    let from_str = string.drop_left(state.target, state.index)
    let starts_with = string.starts_with(from_str, start)

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

fn sequence_of(parsers: List(Parser)) -> Parser {
  fn(state: ParserState) {
    let results: List(Result(ParserState, ParserError)) =
      list.fold(parsers, [], fn(states, parser) {
        case list.last(states) {
          Error(_) -> [parser(state)]
          Ok(last_state) -> {
            case last_state {
              Error(_) -> states
              Ok(val) -> list.append(states, [parser(val)])
            }
          }
        }
      })

    case list.last(results) {
      Error(_) -> Error(EmptySequence(state.index))
      Ok(last) -> {
        case last {
          Error(_) -> Error(BadSequence(state.index))
          Ok(l) -> {
            let parsed: List(Result(Parsed, ParserError)) =
              list.map(results, fn(result) {
                case result {
                  Error(err) -> Error(err)
                  Ok(parser_state) -> Ok(parser_state.result)
                }
              })

            Ok(ParserState(state.target, l.index, Sequence(parsed)))
          }
        }
      }
    }
  }
}

fn run(parser, target) {
  let initial = ParserState(target, 0, StartOfFile)
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
