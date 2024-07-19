import gleam/io

pub fn tap(msg) {
  fn(a) {
    io.debug(#(msg, a))
    a
  }
}

pub fn do(f) {
  fn(a) {
    f(a)
    a
  }
}
