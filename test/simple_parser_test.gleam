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
  "this/is/my/path"
  |> run(parser())
  |> should.be_ok
  |> should.equal(ParserState(Path(["this", "is", "my", "path"]), ""))
}
