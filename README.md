# parz

A simple parser combinator library

> Initially built while trying to learn [Gleam]() and Parser Combinators using
> [The YouTube Series by Low Byte Productions](https://www.youtube.com/playlist?list=PLP29wDx6QmW5yfO1LAgO8kU3aQEj8SIrU)
> and [Understanding Parser Combinators](https://fsharpforfunandprofit.com/posts/understanding-parser-combinators/)

[![Package Version](https://img.shields.io/hexpm/v/parz)](https://hex.pm/packages/parz)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/parz/)

The project exposes the following modules:

1. `parz.` - contains the `run` method which is used for executing a parser
2. `parz/combinators` - the parser combinator library
3. `pars/parsers` - some simple, primitive parsers

## Usage

```sh
gleam add parz
```

```gleam
import parz.{run}
import parz/combinators.{map, separator}
import parz/parsers.{regex, str}

type Path {
  Path(List(String))
}

// parsers are defined at the top level to ensure recursion is
// possible if needed
fn segment() {
  // a parser can be made with a pre-defined base parser from `parz/parsers`
  regex("\\w+")
}

// a more complex parser can be defined by combining other parsers from `parz/combinators`
fn parser() {
  separator(segment(), str("/")) |> map(Path)
}

pub fn main() {
  let result = "my/example/path" |> run(parser())
  // do something with the parsed output
}
```

> For more examples see the `test` directory

Further documentation can be found at <https://hexdocs.pm/parz>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
