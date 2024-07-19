import gleeunit/should
import parz.{run}
import parz/combinators.{
  between, choice, concat, concat_str, label_error, left, many, many1, map,
  maybe, right, sequence,
}
import parz/parsers.{letters, str}
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

pub fn concat_test() {
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

pub fn maybe_test() {
  let parser = maybe(str("x"))

  run(parser, "x")
  |> should.be_ok
  |> should.equal(ParserState("x", ""))

  run(parser, "!")
  |> should.be_ok
  |> should.equal(ParserState("", "!"))

  run(parser, "")
  |> should.be_ok
  |> should.equal(ParserState("", ""))
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
  |> should.equal(#(Content("[hello]"), ""))

  run(parser, "[hello]x")
  |> should.be_ok
  |> should.equal(#(Content("[hello]"), "x"))

  run(parser, "[hellox")
  |> should.be_error
}
