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

  text
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(text, ""))

  "hello!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(text, "!"))

  ""
  |> run(parser)
  |> should.be_error
}

pub fn letters_test() {
  let text = "hello"
  let parser = letters()

  "hello"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(text, ""))

  "hello!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(text, "!"))
}

pub fn digits_test() {
  let text = "1234"
  let parser = digits()

  "1234"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(text, ""))

  "1234!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(text, "!"))
}

pub fn regex_test() {
  let parser = regex("x\\d+x")

  "x123x"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("x123x", ""))

  "x123x!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("x123x", "!"))
}
