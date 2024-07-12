import gleam/io
import gleam/list
import gleam/regex
import gleam/string

pub type ParserError {
  InvalidRegex(index: Int, re: String)
  ExpectedStr(index: Int, expected: String, found: String)
  ExpectedRegex(index: Int, regex: String, found: String)
  UnexpectedEndOfFile
}

pub type Parsed {
  StartOfFile

  // parsers
  Str(String)
  Regex(String)
  Letters(String)
  Digits(String)

  Sequence(List(ParserState))
  Many(List(ParserState))
}

pub type ParserState {
  ParserState(target: String, start: Int, end: Int, result: Parsed)
}

pub type Parser =
  fn(ParserState) -> Result(ParserState, ParserError)

fn str(start) {
  fn(state: ParserState) {
    case string.drop_left(state.target, state.end) {
      "" -> Error(UnexpectedEndOfFile)
      str ->
        case string.starts_with(str, start) {
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

fn sequence_rec(parsers, state, acc) {
  case parsers {
    [] -> Ok([])
    [first, ..rest] ->
      case first(state) {
        Error(err) -> Error(err)
        Ok(ok) ->
          case sequence_rec(rest, ok, acc) {
            Error(err) -> Error(err)
            Ok(rec) -> Ok([ok, ..rec])
          }
      }
  }
}

fn merge(results: Result(List(ParserState), ParserError), t, state: ParserState) {
  case results {
    Error(err) -> Error(err)
    Ok(ok) ->
      case ok {
        [] -> Ok(ParserState(state.target, state.end, state.end, t([])))

        [first, ..rest] ->
          case list.last(rest) {
            Error(_) ->
              Ok(ParserState(first.target, first.start, first.end, t([first])))
            Ok(last) ->
              Ok(ParserState(first.target, first.start, last.end, t(ok)))
          }
      }
  }
}

fn sequence(parsers) -> Parser {
  fn(state: ParserState) {
    let res = sequence_rec(parsers, state, [])

    merge(res, Sequence, state)
  }
}

fn choice(parsers) -> Parser {
  fn(state: ParserState) {
    case parsers {
      [] -> Ok(state)
      [first, ..rest] ->
        case first(state) {
          Ok(ok) -> Ok(ok)
          Error(err) ->
            case rest {
              [] -> Error(err)
              _ -> choice(rest)(state)
            }
        }
    }
  }
}

fn many_rec(parser, state, acc) {
  case parser(state) {
    Error(err) -> Error(err)
    Ok(ok) ->
      case many_rec(parser, ok, acc) {
        Error(_) -> Ok([ok])
        Ok(rec) -> Ok([ok, ..rec])
      }
  }
}

fn many(parser) {
  fn(state: ParserState) { many_rec(parser, state, []) |> merge(Many, state) }
}

fn regex(regex, t) {
  fn(state: ParserState) {
    case regex.from_string(regex) {
      Error(_) -> Error(InvalidRegex(state.end, regex))
      Ok(re) -> {
        let str = string.drop_left(state.target, state.end)

        case regex.scan(re, str) {
          [] -> Error(ExpectedRegex(state.end, regex, str))
          [match, ..] -> {
            Ok(ParserState(
              state.target,
              state.end,
              state.end + string.length(match.content),
              t(match.content),
            ))
          }
        }
      }
    }
  }
}

fn letters() {
  regex("^[A-Za-z]+", Letters)
}

fn digits() {
  regex("^[0-9]+", Digits)
}

fn run(parser, target) {
  let initial = ParserState(target, 0, 0, StartOfFile)
  parser(initial)
}

fn parse(target) {
  let parser =
    sequence([
      letters(),
      digits(),
      str(": "),
      sequence([str("hello"), str(" "), str("world")]),
      many(choice([str("."), str("!"), str("?")])),
    ])
  run(parser, target)
}

pub fn main() {
  let content = "message12: hello world!?!?"
  io.debug(string.length(content))

  let parsed = parse(content)
  io.debug(parsed)
}
