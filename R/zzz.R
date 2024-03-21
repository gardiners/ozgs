.onLoad <- function(libname, pkgname) {
  rlang::run_on_load()
}

#' @export
aus <- new_getter("AUS")

#' @export
lga <- new_getter("LGA")
