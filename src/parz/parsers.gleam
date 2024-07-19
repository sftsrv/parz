import gleam/regex
import gleam/string
import parz/types.{type Parser, ParserState}

pub fn str(start) -> Parser {
  fn(state) {
    case string.starts_with(state, start) {
      False -> Error("Expected " <> start <> "But found " <> state)
      True -> {
        let remaining = string.drop_left(state, string.length(start))
        Ok(ParserState(start, remaining))
      }
    }
  }
}

pub fn regex(regex) {
  fn(state) {
    case regex.from_string(regex) {
      Error(_) -> Error("Invalid Regex Provided " <> regex)
      Ok(re) -> {
        case regex.scan(re, state) {
          [] -> Error("String does not match regex " <> regex)
          [match, ..] -> {
            let remaining =
              string.drop_left(state, string.length(match.content))
            Ok(ParserState(match.content, remaining))
          }
        }
      }
    }
  }
}

pub fn letters() {
  regex("^[A-Za-z]+")
}

pub fn digits() {
  regex("^[0-9]+")
}
