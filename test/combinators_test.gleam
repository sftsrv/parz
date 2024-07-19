import gleeunit/should
import parz.{run}
import parz/combinators.{between, choice, left, many, many1, right, sequence}
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
  |> should.equal(#([], "!"))

  run(parser, "x")
  |> should.be_ok
  |> should.equal(#(["x"], ""))

  run(parser, "xxx")
  |> should.be_ok
  |> should.equal(#(["x", "x", "x"], ""))

  run(parser, "xx!")
  |> should.be_ok
  |> should.equal(#(["x", "x"], "!"))
}

pub fn many1_test() {
  let parser = many1(str("x"))

  run(parser, "!")
  |> should.be_error

  run(parser, "x")
  |> should.be_ok
  |> should.equal(#(["x"], ""))

  run(parser, "xxx")
  |> should.be_ok
  |> should.equal(#(["x", "x", "x"], ""))

  run(parser, "xx!")
  |> should.be_ok
  |> should.equal(#(["x", "x"], "!"))
}
