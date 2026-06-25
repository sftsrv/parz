import gleam/regexp
import gleam/string
import parz/types.{type Parser, ParserState}

/// Create a parser that matches a fixed string literal
pub fn str(start) -> Parser(String) {
  fn(input) {
    case string.starts_with(input, start) {
      False -> Error("Expected " <> start <> " but found " <> input)
      True -> {
        let remaining = string.drop_start(input, string.length(start))
        Ok(ParserState(start, remaining))
      }
    }
  }
}

/// Create a parser that matches a string using a regex
pub fn regex(re_str) {
  fn(input) {
    case regexp.from_string(re_str) {
      Error(_) -> Error("Invalid Regex Provided " <> re_str)
      Ok(re) -> {
        case regexp.scan(re, input) {
          [] ->
            Error(
              "String does not match Regex: " <> re_str <> "String: " <> input,
            )
          [match, ..] -> {
            let remaining =
              string.drop_start(input, string.length(match.content))
            Ok(ParserState(match.content, remaining))
          }
        }
      }
    }
  }
}

/// Utility parser for letters `^[A-Za-z]+`
pub fn letters() {
  regex("^[A-Za-z]+")
}

/// Utility parser for digits `^[0-9]+`
pub fn digits() {
  regex("^[0-9]+")
}

/// Utility parser for whitespace `^\s*`
pub fn whitespace() {
  regex("^\\s*")
}
