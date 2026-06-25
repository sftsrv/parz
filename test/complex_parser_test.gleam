import gleeunit/should
import parz.{run}
import parz/combinators.{
  between, choice, label_error, lazy, left, map, map_token, padded, separator1,
  sequence, try_map,
}
import parz/parsers.{letters, str, whitespace}
import parz/types.{ParserState}

type Type {
  StringType
  BooleanType
  NumberType
  ObjectType(List(Node))
}

type Identifier {
  Identifier(name: String)
}

type Node {
  Node(name: Identifier, kind: Type)
}

type NodePart {
  NodeKind(kind: Type)
  NodeIdentifier(identifier: Identifier)
}

type Ast {
  Ast(List(Node))
}

const input = "
  name: string;
  age: number;
  active: boolean;
  details: {
    meta: {
      other: string;
      inner: {
        count: boolean;
      };
    };
  };
  total: number;
"

const custom_error = "Expected : but found something else"

fn trim(parser) {
  padded(whitespace(), parser)
}

fn identifier() {
  letters()
  |> map(Identifier)
}

fn string_kind() {
  str("string") |> map_token(StringType)
}

fn number_kind() {
  str("number") |> map_token(NumberType)
}

fn boolean_kind() {
  str("boolean") |> map_token(BooleanType)
}

fn object_kind() {
  lazy(fn() {
    between(
      trim(str("{")),
      choice([nodes() |> map(ObjectType)]),
      trim(str("}")),
    )
  })
}

fn kind() {
  choice([string_kind(), number_kind(), boolean_kind(), object_kind()])
}

fn node() {
  sequence([
    left(identifier(), trim(str(":")) |> label_error(custom_error))
      |> map(NodeIdentifier),
    left(kind(), str(";")) |> label_error("expected ;") |> map(NodeKind),
  ])
  |> try_map(fn(ok) {
    case ok {
      [NodeIdentifier(i), NodeKind(k)] -> Ok(Node(i, k))
      _ -> Error("Failed to match identifier:kind")
    }
  })
}

fn nodes() {
  separator1(node(), whitespace())
}

fn parser() {
  trim(nodes()) |> map(Ast)
}

pub fn complex_parser_test() {
  run(parser(), input)
  |> should.be_ok
  |> should.equal(ParserState(
    Ast([
      Node(Identifier("name"), StringType),
      Node(Identifier("age"), NumberType),
      Node(Identifier("active"), BooleanType),
      Node(
        Identifier("details"),
        ObjectType([
          Node(
            Identifier("meta"),
            ObjectType([
              Node(Identifier("other"), StringType),
              Node(
                Identifier("inner"),
                ObjectType([Node(Identifier("count"), BooleanType)]),
              ),
            ]),
          ),
        ]),
      ),
      Node(Identifier("total"), NumberType),
    ]),
    "",
  ))
}

pub fn complex_parser_error_test() {
  run(parser(), "name;number")
  |> should.be_error
  |> should.equal(custom_error)
}
