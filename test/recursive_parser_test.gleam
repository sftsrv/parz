import gleeunit/should
import parz.{run}
import parz/combinators.{between, choice, map, recurser, sequence, try_map}
import parz/parsers.{str}
import parz/types.{ParserState}

type Op {
  Plus
  Minus
}

type Node {
  Const(n: String)
  Operation(l: String, op: Op, r: String)
  Group(inner: Node)
}

type Ast {
  Ast(Node)
}

// example implementation is only recursive on
// the brackets for now. Expressions only support one
// operation per set of brackets
const input = "((2-1))"

fn parser() {
  let num = parsers.digits()
  let constant = num |> map(Const)

  let operator = choice([str("+"), str("-")])
  let operation =
    sequence([num, operator, num])
    |> try_map(fn(parsed) {
      case parsed {
        [left, operator, right] -> {
          case operator {
            "+" -> Ok(Operation(left, Plus, right))
            "-" -> Ok(Operation(left, Minus, right))
            _ -> Error("unexpected operator matched")
          }
        }
        _ -> Error("invalid sequence matched")
      }
    })

  let expression = choice([operation, constant])

  let group =
    recurser(expression, fn(group) {
      between(str("("), choice([group |> map(Group), expression]), str(")"))
    })

  let parser = group |> map(Ast)
  parser
}

pub fn recursive_parser_test() {
  run(parser(), input)
  |> should.be_ok
  |> should.equal(ParserState(Ast(Group(Group(Operation("1", Plus, "2")))), ""))
}
