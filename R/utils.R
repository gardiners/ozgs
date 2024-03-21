# Match anything if NULL.
`%maybe%` <- function(x, y) {
  if (is.null(x)) {
    rep(TRUE, length(y))
  } else {
    x == y
  }
}

# Let cli print the word NULL if needed.
nullchar <- function(x) {
  if (is.null(x)) {
    "NULL"
  }
  else {
    x
  }
}
