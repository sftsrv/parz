import gleeunit/should
import parz.{run}
import parz/combinators.{between, choice, lazy, map}
import parz/parsers.{str}
import parz/types.{ParserState}

type Node {
  Const(n: String)
  Group(inner: Node)
}

type Ast {
  Ast(Node)
}

// example implementation is only recursive on
// the brackets for now
const input = "(((1)))"

fn constant() {
  parsers.digits() |> map(Const)
}

fn group() {
  lazy(fn() { between(str("("), choice([constant(), group()]), str(")")) })
  |> map(Group)
}

fn parser() {
  group() |> map(Ast)
}

pub fn recursive_parser_test() {
  input
  |> run(parser())
  |> should.be_ok
  |> should.equal(ParserState(Ast(Group(Group(Group(Const("1"))))), ""))
}
