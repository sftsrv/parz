import gleam/list
import parz/types.{type Parser, type ParserState, ParserState}
import parz/util.{tap}

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

pub fn sequence(parsers) {
  fn(state) { sequence_rec(parsers, state, []) }
}

pub fn choice(parsers: List(Parser)) {
  fn(state) {
    case parsers {
      [] -> Error("No more choices provided")
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

pub fn right(l: Parser, r: Parser) -> Parser {
  fn(state) {
    case l(state) {
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
  fn(state) {
    case l(state) {
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
  fn(state) {
    case l(state) {
      Error(err) -> Error(err)
      Ok(okl) ->
        case left(keep, r)(okl.remaining) {
          Error(err) -> Error(err)
          Ok(okr) -> Ok(ParserState(okr.matched, okr.remaining))
        }
    }
  }
}

fn many_rec(parser: Parser, state, acc) {
  case parser(state) {
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
  fn(state) { many_rec(parser, state, []) }
}

pub fn many(parser: Parser) {
  fn(state) {
    case many1(parser)(state) {
      Error(_) -> Ok(#([], state))
      Ok(ok) -> Ok(ok)
    }
  }
}
