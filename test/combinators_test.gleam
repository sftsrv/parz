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

  "hello/"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("hello", ""))

  "hello/!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("hello", "!"))

  "hello"
  |> run(parser)
  |> should.be_error
}

pub fn right_test() {
  let parser = right(str("/"), str("hello"))

  "/hello"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("hello", ""))

  "/hello!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("hello", "!"))

  "hello"
  |> run(parser)
  |> should.be_error
}

pub fn between_test() {
  let parser = between(str("["), letters(), str("]"))

  "[hello]"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("hello", ""))

  "[hello]!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("hello", "!"))

  "[hello"
  |> run(parser)
  |> should.be_error
}

pub fn choice_test() {
  let parser = choice([str("x"), str("y"), str("z")])

  "x"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("x", ""))

  "y"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("y", ""))

  "z"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("z", ""))

  "x!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("x", "!"))

  "a"
  |> run(parser)
  |> should.be_error

  "x"
  |> run(choice([]))
  |> should.be_error
}

pub fn many_test() {
  let parser = many(str("x"))

  "!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState([], "!"))

  "x"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x"], ""))

  "xxx"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x", "x", "x"], ""))

  "xx!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x", "x"], "!"))
}

pub fn many1_test() {
  let parser = many1(str("x"))

  "!"
  |> run(parser)
  |> should.be_error

  "x"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x"], ""))

  "xxx"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x", "x", "x"], ""))

  "xx!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x", "x"], "!"))
}

pub fn sequence_test() {
  let parser = sequence([str("["), letters(), str("]")])

  "[hello]"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["[", "hello", "]"], ""))

  "[hello]!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["[", "hello", "]"], "!"))

  "[hello"
  |> run(parser)
  |> should.be_error
}

pub fn concat_str_test() {
  let parser = concat_str(sequence([str("["), letters(), str("]")]))

  "[hello]"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("[hello]", ""))

  "[hello]!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("[hello]", "!"))

  "[hello"
  |> run(parser)
  |> should.be_error
}

pub fn label_error_test() {
  let message = "Expected [letters]"
  let parser =
    concat_str(sequence([str("["), letters(), str("]")]))
    |> label_error(message)

  "[hello]"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState("[hello]", ""))

  "[hellox"
  |> run(parser)
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

  "[hello]"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(Content("[hello]"), ""))

  "[hello]x"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(Content("[hello]"), "x"))

  "[hellox"
  |> run(parser)
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

  "[hello]"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(Content("hello"), ""))

  "[hello]x"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(Content("hello"), "x"))

  "[]x"
  |> run(parser)
  |> should.be_error
  |> should.equal(error)

  "[hellox"
  |> run(parser)
  |> should.be_error
}

type Token {
  Token
}

pub fn map_token_test() {
  let parser =
    str("hello")
    |> map_token(Token)

  "hello"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(Token, ""))

  "hellox"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(Token, "x"))

  "xhello"
  |> run(parser)
  |> should.be_error
}

pub fn as_list_test() {
  let parser = as_list(str("x"))

  "x"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x"], ""))

  "x!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x"], "!"))

  "xx"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["x"], "x"))

  "[hellox"
  |> run(parser)
  |> should.be_error
}

pub fn separator_test() {
  let parser = separator(letters(), str(";"))

  "well;hello;world"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["well", "hello", "world"], ""))

  "hello!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["hello"], "!"))

  "!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState([], "!"))
}

pub fn separator1_test() {
  let parser = separator1(letters(), str(";"))

  "well;hello;world"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["well", "hello", "world"], ""))

  "hello!"
  |> run(parser)
  |> should.be_ok
  |> should.equal(ParserState(["hello"], "!"))

  "!"
  |> run(parser)
  |> should.be_error
}
