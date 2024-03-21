#' Generate a human-readable cache key from a specification for an ASGS request
#'
#' @inheritParams get_geograpghy
#' @return Returns a (somewhat) descriptive key.
asgs_key <- function(geography, edition, reference_date, layer, where,
                     filter_geom, predicate, ...) {
  c("asgs",
    edition,
    geography,
    reference_date,
    layer,
    rlang::hash(list(geography, edition, reference_date, layer, where,
                     filter_geom, predicate, ...))) |>
    purrr::compact() |>
    paste(collapse = "") |>
    tolower()
}

# Use a memory cache by default
rlang::on_load({
  if (is.null(getOption("ozgs.cache"))) {
    options("ozgs.cache" = cachem::cache_mem())
  }
})
