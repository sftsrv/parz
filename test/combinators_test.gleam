import gleeunit/should
import parz.{run}
import parz/combinators.{
  as_list, between, choice, concat_str, label_error, left, many, many1, map,
  map_token, right, separator, separator1, sequence, try_map,
}
import parz/parsers.{letters, regex, str}
import parz/types.{ParserState}

pub fn left_test() {
  let parser = left(str("hello"), str("/"))

  run(parser, "hello/")
  |> should.be_ok
  |> should.equal(ParserState("hello", ""))

  run(parser, "hello/!")
  |> should.be_ok
  |> should.equal(ParserState("hello", "!"))

  run(parser, "hello")
  |> should.be_error
}

pub fn right_test() {
  let parser = right(str("/"), str("hello"))

  run(parser, "/hello")
  |> should.be_ok
  |> should.equal(ParserState("hello", ""))

  run(parser, "/hello!")
  |> should.be_ok
  |> should.equal(ParserState("hello", "!"))

  run(parser, "hello")
  |> should.be_error
}

pub fn between_test() {
  let parser = between(str("["), letters(), str("]"))

  run(parser, "[hello]")
  |> should.be_ok
  |> should.equal(ParserState("hello", ""))

  run(parser, "[hello]!")
  |> should.be_ok
  |> should.equal(ParserState("hello", "!"))

  run(parser, "[hello")
  |> should.be_error
}

pub fn choice_test() {
  let parser = choice([str("x"), str("y"), str("z")])

  run(parser, "x")
  |> should.be_ok
  |> should.equal(ParserState("x", ""))

  run(parser, "y")
  |> should.be_ok
  |> should.equal(ParserState("y", ""))

  run(parser, "z")
  |> should.be_ok
  |> should.equal(ParserState("z", ""))

  run(parser, "x!")
  |> should.be_ok
  |> should.equal(ParserState("x", "!"))

  run(parser, "a")
  |> should.be_error

  run(choice([]), "x")
  |> should.be_error
}

pub fn many_test() {
  let parser = many(str("x"))

  run(parser, "!")
  |> should.be_ok
  |> should.equal(ParserState([], "!"))

  run(parser, "x")
  |> should.be_ok
  |> should.equal(ParserState(["x"], ""))

  run(parser, "xxx")
  |> should.be_ok
  |> should.equal(ParserState(["x", "x", "x"], ""))

  run(parser, "xx!")
  |> should.be_ok
  |> should.equal(ParserState(["x", "x"], "!"))
}

pub fn many1_test() {
  let parser = many1(str("x"))

  run(parser, "!")
  |> should.be_error

  run(parser, "x")
  |> should.be_ok
  |> should.equal(ParserState(["x"], ""))

  run(parser, "xxx")
  |> should.be_ok
  |> should.equal(ParserState(["x", "x", "x"], ""))

  run(parser, "xx!")
  |> should.be_ok
  |> should.equal(ParserState(["x", "x"], "!"))
}

pub fn sequence_test() {
  let parser = sequence([str("["), letters(), str("]")])

  run(parser, "[hello]")
  |> should.be_ok
  |> should.equal(ParserState(["[", "hello", "]"], ""))

  run(parser, "[hello]!")
  |> should.be_ok
  |> should.equal(ParserState(["[", "hello", "]"], "!"))

  run(parser, "[hello")
  |> should.be_error
}

pub fn concat_str_test() {
  let parser = concat_str(sequence([str("["), letters(), str("]")]))

  run(parser, "[hello]")
  |> should.be_ok
  |> should.equal(ParserState("[hello]", ""))

  run(parser, "[hello]!")
  |> should.be_ok
  |> should.equal(ParserState("[hello]", "!"))

  run(parser, "[hello")
  |> should.be_error
}

pub fn label_error_test() {
  let message = "Expected [letters]"
  let parser =
    concat_str(sequence([str("["), letters(), str("]")]))
    |> label_error(message)

  run(parser, "[hello]")
  |> should.be_ok
  |> should.equal(ParserState("[hello]", ""))

  run(parser, "[hellox")
  |> should.be_error
  |> should.equal(message)
}

type Transformed {
  NoContent
  Content(String)
}

pub fn map_test() {
  let parser =
    concat_str(sequence([str("["), letters(), str("]")]))
    |> map(fn(ok) {
      case ok {
        "" -> NoContent
        content -> Content(content)
      }
    })

  run(parser, "[hello]")
  |> should.be_ok
  |> should.equal(ParserState(Content("[hello]"), ""))

  run(parser, "[hello]x")
  |> should.be_ok
  |> should.equal(ParserState(Content("[hello]"), "x"))

  run(parser, "[hellox")
  |> should.be_error
}

pub fn try_map_test() {
  let error = "No content"
  let parser =
    between(str("["), regex("^[A-Za-z]*"), str("]"))
    |> try_map(fn(ok) {
      case ok {
        "" -> Error(error)
        content -> Ok(Content(content))
      }
    })

  run(parser, "[hello]")
  |> should.be_ok
  |> should.equal(ParserState(Content("hello"), ""))

  run(parser, "[hello]x")
  |> should.be_ok
  |> should.equal(ParserState(Content("hello"), "x"))

  run(parser, "[]x")
  |> should.be_error
  |> should.equal(error)

  run(parser, "[hellox")
  |> should.be_error
}

type Token {
  Token
}

pub fn map_token_test() {
  let parser =
    str("hello")
    |> map_token(Token)

  run(parser, "hello")
  |> should.be_ok
  |> should.equal(ParserState(Token, ""))

  run(parser, "hellox")
  |> should.be_ok
  |> should.equal(ParserState(Token, "x"))

  run(parser, "xhello")
  |> should.be_error
}

pub fn as_list_test() {
  let parser = as_list(str("x"))

  run(parser, "x")
  |> should.be_ok
  |> should.equal(ParserState(["x"], ""))

  run(parser, "x!")
  |> should.be_ok
  |> should.equal(ParserState(["x"], "!"))

  run(parser, "xx")
  |> should.be_ok
  |> should.equal(ParserState(["x"], "x"))

  run(parser, "[hellox")
  |> should.be_error
}

pub fn separator_test() {
  let parser = separator(letters(), str(";"))

  run(parser, "well;hello;world")
  |> should.be_ok
  |> should.equal(ParserState(["well", "hello", "world"], ""))

  run(parser, "hello!")
  |> should.be_ok
  |> should.equal(ParserState(["hello"], "!"))

  run(parser, "!")
  |> should.be_ok
  |> should.equal(ParserState([], "!"))
}

pub fn separator1_test() {
  let parser = separator1(letters(), str(";"))

  run(parser, "well;hello;world")
  |> should.be_ok
  |> should.equal(ParserState(["well", "hello", "world"], ""))

  run(parser, "hello!")
  |> should.be_ok
  |> should.equal(ParserState(["hello"], "!"))

  run(parser, "!")
  |> should.be_error
}
