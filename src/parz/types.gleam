pub type ParserState(a) {
  ParserState(matched: a, remaining: String)
}

pub type Err =
  String

pub type Parser(a) =
  fn(String) -> Result(ParserState(a), Err)
