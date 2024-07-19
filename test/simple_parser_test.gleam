import gleeunit/should
import parz.{run}
import parz/combinators.{label_error, left, map, separator1, sequence}
import parz/parsers.{letters, regex, str}
import parz/types.{ParserState}

type Kind {
  StringKind
  BooleanKind
  NumberKind
  UnknownKind
}

type Identifier {
  Identifier(name: String)
}

type Node {
  UnknownNode
  Node(name: Identifier, kind: Kind)
}

type NodePart {
  K(kind: Kind)
  I(identifier: Identifier)
}

type AST {
  AST(List(Node))
}

const input = "name:string;
age:number;
active:boolean;"

const custom_error = "Expected : but found something else"

fn parser() {
  let name =
    left(letters(), str(":") |> label_error(custom_error))
    |> map(Identifier)
    |> map(I)

  let kind =
    left(letters(), str(";"))
    |> map(fn(ok) {
      case ok {
        "string" -> StringKind
        "number" -> NumberKind
        "boolean" -> BooleanKind
        _ -> UnknownKind
      }
    })
    |> map(K)

  let node =
    sequence([name, kind])
    |> map(fn(ok) {
      case ok {
        [I(i), K(k)] -> Node(i, k)
        _ -> UnknownNode
      }
    })

  let whitespace = regex("\\s*")

  let parser = separator1(node, whitespace) |> map(AST)

  parser
}

pub fn simple_parser_test() {
  run(parser(), input)
  |> should.be_ok
  |> should.equal(ParserState(
    AST([
      Node(Identifier("name"), StringKind),
      Node(Identifier("age"), NumberKind),
      Node(Identifier("active"), BooleanKind),
    ]),
    "",
  ))
}

pub fn simple_parser_error_test() {
  run(parser(), "name;number")
  |> should.be_error
  |> should.equal(custom_error)
}
