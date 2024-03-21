.onLoad <- function(libname, pkgname) {
  rlang::run_on_load()
}

# Use a memory cache by default
rlang::on_load({
  if (is.null(getOption("ozgs.cache"))) {
    options("ozgs.cache" = cachem::cache_mem())
  }
})

#' @export
aus <- new_getter("AUS")

#' @export
lga <- new_getter("LGA")
