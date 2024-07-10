import gleam/io
import gleam/list
import gleam/regex
import gleam/result
import gleam/string

pub type ParserError {
  InvalidRegex(index: Int, re: String)
  EmptySequence(index: Int)
  EmptyChoices(index: Int)
  ExpectedStr(index: Int, expected: String, found: String)
  ExpectedRegex(index: Int, regex: String, found: String)
  UnexpectedEndOfFile
}

pub type Parsed(a) {
  StartOfFile

  // parsers
  Str(String)
  Regex(String)
  Letters(String)
  Digits(String)

  // combinators
  Sequence(List(ParserState(a)))
  Choice(ParserState(a))
}

pub type ParserState(result) {
  ParserState(target: String, start: Int, end: Int, result)
}

fn str(start) {
  fn(state: ParserState(a)) {
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

fn sequence_of_rec(parsers, state, results) {
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

fn sequence_of(parsers) {
  fn(state: ParserState(a)) {
    let result = sequence_of_rec(parsers, state, [])

    case result {
      Error(err) -> Error(err)
      Ok(ok) -> {
        case list.last(ok) {
          Error(_) -> Error(EmptySequence(state.end))
          Ok(last) ->
            Ok(ParserState(last.target, state.end, last.end, Sequence(ok)))
        }
      }
    }
  }
}

fn choice_of_rec(
  parsers,
  state: ParserState(a),
) -> Result(ParserState(b), ParserError) {
  case parsers {
    [] -> Error(EmptyChoices(state.end))
    [first, ..rest] -> {
      case first(state) {
        Error(_) -> choice_of_rec(rest, state)
        Ok(ok) -> Ok(ok)
      }
    }
  }
}

fn choice_of(parsers) {
  fn(state) {
    choice_of_rec(parsers, state)
    |> result.map(fn(res) {
      ParserState(res.target, res.start, res.end, Choice(res))
    })
  }
}

fn regex(regex, t) {
  fn(state: ParserState(a)) {
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
    sequence_of([
      letters(),
      digits(),
      str(": "),
      str("hello"),
      str(" "),
      str("world"),
      choice_of([str("!"), str("")]),
    ])
  run(parser, target)
}

pub fn main() {
  let parsed = parse("message12: hello world!")
  io.debug(parsed)
}
