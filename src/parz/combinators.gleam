import gleam/string
import parz/types.{type Parser, type ParserState, ParserState}

fn sequence_rec(parsers: List(Parser), input, acc) {
  case parsers {
    [] -> Ok(#([], input))
    [first, ..rest] ->
      case first(input) {
        Error(err) -> Error(err)
        Ok(ok) ->
          case sequence_rec(rest, ok.remaining, acc) {
            Error(err) -> Error(err)
            Ok(rec) -> {
              let #(matches, remaining) = rec
              Ok(#([ok.matched, ..matches], remaining))
            }
          }
      }
  }
}

pub fn sequence(parsers: List(Parser)) {
  fn(input) { sequence_rec(parsers, input, []) }
}

pub fn choice(parsers: List(Parser)) {
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

pub fn right(l: Parser, r: Parser) -> Parser {
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

pub fn left(l: Parser, r: Parser) -> Parser {
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

pub fn between(l: Parser, keep: Parser, r: Parser) -> Parser {
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

pub fn maybe(parser) {
  fn(input) {
    case parser(input) {
      Ok(ok) -> Ok(ok)
      Error(_) -> Ok(ParserState("", input))
    }
  }
}

fn many_rec(parser: Parser, input, acc) {
  case parser(input) {
    Error(err) -> Error(err)
    Ok(ok) -> {
      case many_rec(parser, ok.remaining, acc) {
        Error(_) -> Ok(#([ok.matched], ok.remaining))
        Ok(rec) -> {
          let #(matches, remaining) = rec
          Ok(#([ok.matched, ..matches], remaining))
        }
      }
    }
  }
}

pub fn many1(parser: Parser) {
  fn(input) { many_rec(parser, input, []) }
}

pub fn many(parser: Parser) {
  fn(input) {
    case many1(parser)(input) {
      Error(_) -> Ok(#([], input))
      Ok(ok) -> Ok(ok)
    }
  }
}

pub fn concat(parser) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) -> {
        let #(parts, remainder) = ok

        Ok(ParserState(string.concat(parts), remainder))
      }
    }
  }
}

pub fn label_error(parser, message) {
  fn(input) {
    case parser(input) {
      Ok(ok) -> Ok(ok)
      Error(_) -> Error(message)
    }
  }
}

pub fn map(parser: Parser, transform) {
  fn(input) {
    case parser(input) {
      Error(err) -> Error(err)
      Ok(ok) -> Ok(#(transform(ok.matched), ok.remaining))
    }
  }
}
