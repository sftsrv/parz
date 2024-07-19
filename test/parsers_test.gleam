import gleeunit
import gleeunit/should
import parz.{run}
import parz/parsers.{digits, letters, regex, str}
import parz/types.{ParserState}

pub fn main() {
  gleeunit.main()
}

pub fn str_test() {
  let text = "hello"
  let parser = str(text)

  run(parser, text)
  |> should.be_ok
  |> should.equal(ParserState(text, ""))

  run(parser, "hello!")
  |> should.be_ok
  |> should.equal(ParserState(text, "!"))

  run(parser, "")
  |> should.be_error
}

pub fn letters_test() {
  let text = "hello"
  let parser = letters()

  run(parser, "hello")
  |> should.be_ok
  |> should.equal(ParserState(text, ""))

  run(parser, "hello!")
  |> should.be_ok
  |> should.equal(ParserState(text, "!"))
}

pub fn digits_test() {
  let text = "1234"
  let parser = digits()

  run(parser, "1234")
  |> should.be_ok
  |> should.equal(ParserState(text, ""))

  run(parser, "1234!")
  |> should.be_ok
  |> should.equal(ParserState(text, "!"))
}

pub fn regex_test() {
  let parser = regex("x\\d+x")

  run(parser, "x123x")
  |> should.be_ok
  |> should.equal(ParserState("x123x", ""))

  run(parser, "x123x!")
  |> should.be_ok
  |> should.equal(ParserState("x123x", "!"))
}
