import gleam/list
import gleam/string
import parz/types.{type Parser, type ParserState, ParserState}

fn sequence_rec(
  parsers: List(Parser(a)),
  input: String,
) -> Result(ParserState(List(a)), String) {
  case parsers {
    [] -> Ok(ParserState([], input))
    [first, ..rest] ->
      case first(input) {
        Error(err) -> Error(err)
        Ok(ok) ->
          case sequence_rec(rest, ok.remaining) {
            Error(err) -> Error(err)
            Ok(rec) ->
              Ok(ParserState([ok.matched, ..rec.matched], rec.remaining))
          }
      }
  }
}

/// Parses the given parsers one after the other and returns the results
/// in a List
pub fn sequence(
  parsers: List(Parser(a)),
) -> fn(String) -> Result(ParserState(List(a)), String) {
  fn(input) { sequence_rec(parsers, input) }
}

/// Uses any of the given parsers, returning the result from the first
/// succcessful one
pub fn choice(
  parsers: List(Parser(a)),
) -> fn(String) -> Result(ParserState(a), String) {
  fn(input) {
    case parsers {
      [] -> Error("No more choices provided")
      [first, ..rest] ->
        case first(input) {
          Ok(ok) -> Ok(ok)
          Error(err) ->
            case rest {
              [] -> Error(err)
              _ -> choice(rest)(input)
            }
        }
    }
  }
}

/// Takes the result of the parser on the right, discarding the left result
pub fn right(l: Parser(a), r: Parser(b)) -> Parser(b) {
  fn(input) {
    case l(input) {
      Error(err) -> Error(err)
      Ok(okl) ->
        case r(okl.remaining) {
          Error(err) -> Error(err)
          Ok(okr) -> Ok(ParserState(okr.matched, okr.remaining))
        }
    }
  }
}

/// Takes the result of the parser on the left, discarding the right result
pub fn left(l: Parser(a), r: Parser(b)) -> Parser(a) {
  fn(input) {
    case l(input) {
      Error(err) -> Error(err)
      Ok(okl) ->
        case r(okl.remaining) {
          Error(err) -> Error(err)
          Ok(okr) -> Ok(ParserState(okl.matched, okr.remaining))
        }
    }
  }
}

// Takes the value between two parsers. Keeps the middle result. Discards the
// left and right values
pub fn between(l: Parser(a), keep: Parser(b), r: Parser(c)) -> Parser(b) {
  fn(input) {
    case l(input) {
      Error(err) -> Error(err)
      Ok(okl) ->
        case left(keep, r)(okl.remaining) {
          Error(err) -> Error(err)
          Ok(okr) -> Ok(ParserState(okr.matched, okr.remaining))
        }
    }
  }
}

fn many_rec(
  parser: Parser(a),
  input: String,
) -> Result(ParserState(List(a)), String) {
  case parser(input) {
    Error(err) -> Error(err)
    Ok(ok) -> {
      case many_rec(parser, ok.remaining) {
        Error(_) -> Ok(ParserState([ok.matched], ok.remaining))
        Ok(rec) -> {
          Ok(ParserState([ok.matched, ..rec.matched], rec.remaining))
        }
      }
    }
  }
}

/// Tries match the given parser at least once, and as many more times as
/// possible. Returns a list of all parsed results
pub fn many1(
  parser: Parser(a),
) -> fn(String) -> Result(ParserState(List(a)), String) {
  fn(input) { many_rec(parser, input) }
}

/// Tries match the given parser as many times as possible. Returns a list of
/// all parsed results
pub fn many(
  parser: Parser(a),
) -> fn(String) -> Result(ParserState(List(a)), b) {
  fn(input) {
    case many1(parser)(input) {
      Error(_) -> Ok(ParserState([], input))
      Ok(ok) -> Ok(ok)
    }
  }
}

/// Join the results of multiple string-parsers into a single string
pub fn concat_str(
  parser: fn(String) -> Result(ParserState(List(String)), String),
) -> fn(String) -> Result(ParserState(String), String) {
  map(parser, string.concat)
}

/// Customize the error message of a parser
pub fn label_error(
  parser parser: fn(a) -> Result(b, c),
  message message: d,
) -> fn(a) -> Result(b, d) {
  fn(input) {
    case parser(input) {
      Ok(ok) -> Ok(ok)
      Error(_) -> Error(message)
    }
  }
}

/// Call a transform on the successful result of a parser
pub fn map(
  parser parser: Parser(a),
  transform transform: fn(a) -> b,
) -> fn(String) -> Result(ParserState(b), String) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) -> Ok(ParserState(transform(ok.matched), ok.remaining))
    }
  }
}

/// Convert a parsed result into a fixed-value token
pub fn map_token(
  parser parser: Parser(a),
  token token: b,
) -> fn(String) -> Result(ParserState(b), String) {
  map(parser, fn(_) { token })
}

/// Call a transform that may fail on the successful result of a parser
pub fn try_map(
  parser parser: Parser(a),
  transform transform: fn(a) -> Result(b, String),
) -> fn(String) -> Result(ParserState(b), String) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) ->
        case transform(ok.matched) {
          Error(err) -> Error(err)
          Ok(t) -> Ok(ParserState(t, ok.remaining))
        }
    }
  }
}

/// Creates a List from a single parser. Useful for composing with other
/// parsers that may return a List of results
pub fn as_list(
  parser: Parser(a),
) -> fn(String) -> Result(ParserState(List(a)), String) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) -> Ok(ParserState([ok.matched], ok.remaining))
    }
  }
}

/// Parses a list of the given parser separated by sep at least once.
/// The results of the given parser will be returned as a List
pub fn separator1(
  parser parser: Parser(a),
  sep sep: Parser(_),
) -> fn(String) -> Result(ParserState(List(a)), String) {
  choice([
    sequence([as_list(parser), many(right(sep, parser))]) |> map(list.flatten),
    as_list(parser),
  ])
}

/// Parses a list of the given parser separated by sep. The results of the
/// given parser will be returned as a List
pub fn separator(
  parser parser: Parser(a),
  sep sep: Parser(_),
) -> fn(String) -> Result(ParserState(List(a)), b) {
  fn(input) {
    case separator1(parser, sep)(input) {
      Error(_) -> Ok(ParserState([], input))
      Ok(ok) -> Ok(ok)
    }
  }
}

/// Takes a thunk that will be lazily evaluated to a parser. This makes it
/// possible to define recursive parsers
pub fn lazy(
  thunk: fn() -> Parser(a),
) -> fn(String) -> Result(ParserState(a), String) {
  fn(state) { thunk()(state) }
}

/// Pads the parser with the given padding parser on the left and right side.
/// Returns the result of the main parser 
pub fn padded(
  padding padding: fn(String) -> Result(ParserState(a), String),
  parser parser: fn(String) -> Result(ParserState(b), String),
) -> fn(String) -> Result(ParserState(b), String) {
  between(padding, parser, padding)
}
