import gleeunit/should
import parz.{run}
import parz/combinators.{map, separator}
import parz/parsers.{regex, str}
import parz/types.{ParserState}

type Path {
  Path(List(String))
}

fn segment() {
  regex("(\\w|\\.)+")
}

fn parser() {
  separator(segment(), str("/")) |> map(Path)
}

pub fn simple_parser_test() {
  run(parser(), "this/is/my/path")
  |> should.be_ok
  |> should.equal(ParserState(Path(["this", "is", "my", "path"]), ""))
}
