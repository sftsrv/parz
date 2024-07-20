import gleeunit/should
import parz.{run}
import parz/combinators.{
  choice, label_error, left, map, separator1, sequence, try_map,
}
import parz/parsers.{letters, regex, str}
import parz/types.{ParserState}

type Kind {
  StringKind
  BooleanKind
  NumberKind
}

type Identifier {
  Identifier(name: String)
}

type Node {
  Node(name: Identifier, kind: Kind)
}

type NodePart {
  NodeKind(kind: Kind)
  NodeIdentifier(identifier: Identifier)
}

type Ast {
  Ast(List(Node))
}

const input = "name:string;
age:number;
active:boolean;"

const custom_error = "Expected : but found something else"

fn parser() {
  let identifier =
    letters()
    |> map(Identifier)

  let string_kind = str("string") |> map(fn(_) { StringKind })
  let number_kind = str("number") |> map(fn(_) { NumberKind })
  let boolean_kind = str("boolean") |> map(fn(_) { BooleanKind })

  let kind = choice([string_kind, number_kind, boolean_kind])
  let node =
    sequence([
      left(identifier, str(":") |> label_error(custom_error))
        |> map(NodeIdentifier),
      left(kind, str(";")) |> map(NodeKind),
    ])
    |> try_map(fn(ok) {
      case ok {
        [NodeIdentifier(i), NodeKind(k)] -> Ok(Node(i, k))
        _ -> Error("Failed to match identifier:kind")
      }
    })

  let whitespace = regex("\\s*")

  let parser = separator1(node, whitespace) |> map(Ast)

  parser
}

pub fn simple_parser_test() {
  run(parser(), input)
  |> should.be_ok
  |> should.equal(ParserState(
    Ast([
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
