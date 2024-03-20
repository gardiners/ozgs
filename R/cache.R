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
