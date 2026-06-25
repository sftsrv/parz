# parz

A simple parser combinator library

> Trying to learn [Gleam]() while also Learning about Parser Combinators using
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
import pars/combinators
import pars/parsers

pub fn parser() {
  // .. define a parser using combinators and/or parsers
}


pub fn main() {
  let result = run(parser, content_to_parse)
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
