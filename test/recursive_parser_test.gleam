import gleeunit/should
import parz.{run}
import parz/combinators.{between, choice, map, recurser}
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
// the brackets for now. Expressions only support one
// operation per set of brackets
const input = "((((1))))"

fn parser() {
  let num = parsers.digits()
  let constant = num |> map(Const)

  let group =
    recurser(constant, fn(group) {
      between(str("("), choice([group |> map(Group), constant]), str(")"))
    })

  let parser = group |> map(Ast)
  parser
}

pub fn recursive_parser_test() {
  run(parser(), input)
  |> should.be_ok
  |> should.equal(ParserState(Ast(Group(Group(Group(Group(Const("1")))))), ""))
}
