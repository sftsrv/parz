import gleam/regex
import gleam/string
import parz/types.{type Parser, ParserState}

pub fn str(start) -> Parser(String) {
  fn(input) {
    case string.starts_with(input, start) {
      False -> Error("Expected " <> start <> " but found " <> input)
      True -> {
        let remaining = string.drop_left(input, string.length(start))
        Ok(ParserState(start, remaining))
      }
    }
  }
}

pub fn regex(regex) {
  fn(input) {
    case regex.from_string(regex) {
      Error(_) -> Error("Invalid Regex Provided " <> regex)
      Ok(re) -> {
        case regex.scan(re, input) {
          [] -> Error("String does not match regex " <> regex)
          [match, ..] -> {
            let remaining =
              string.drop_left(input, string.length(match.content))
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
