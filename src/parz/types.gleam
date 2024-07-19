pub type ParserState {
  ParserState(matched: String, remaining: String)
}

pub type Err =
  String

pub type Parser =
  fn(String) -> Result(ParserState, Err)
