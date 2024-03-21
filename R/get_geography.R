#' Fetch a geography from the ASGS web service
#'
#' @param geography
#' @param edition
#' @param reference_date
#' @param layer
#' @param where
#' @param filter_geom
#' @param predicate
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
get_geography <- function(geography,
                          edition = NULL,
                          reference_date = NULL,
                          layer = c("gen", "full", "point"),
                          where = NULL,
                          filter_geom = NULL,
                          predicate = "intersects",
                          cache = getOption("ozgs.cache"),
                          ...) {
  geography <- match.arg(geography, unique(services$geography))
  layer <- match.arg(layer)
  furl <- get_service_url(geography, edition, reference_date, layer)

  # Try the cache
  key <- asgs_key(geography, edition, reference_date, layer, where, filter_geom,
                  predicate, ...)
  result <- cache$get(key)

  if (cachem::is.key_missing(result)) {
    # Cache miss: fetch the requested objects from the web service and store
    fresh_result <- arcgislayers::arc_read(url = furl,
                                           where = where,
                                           filter_geom = filter_geom,
                                           predicate = predicate,
                                           ...)
    cache$set(key, fresh_result)
    fresh_result
  } else {
    # Cache hit
    result
  }
}

# Generate a geography-getter, given the name of an ASGS geography
new_getter <- function(geography_name) {
  args <- rlang::fn_fmls(get_geography)
  args$geography <- NULL
  geography <- geography_name
  rlang::new_function(args, body = rlang::fn_body(get_geography))
}

get_service_url <- function(geography, edition, reference_date, layer) {
  url_suffix <- switch(layer,
                       "gen" = "/1",
                       "full" = "/0",
                       "point" = "/2")
  candidates <- services[geography %maybe% services$geography &
                           edition %maybe% services$edition &
                           reference_date %maybe% services$reference_date,]
  check_specificity(candidates, geography, edition, reference_date)
  paste0(candidates$url, url_suffix)
}

check_specificity <- function(candidates,
                              geography = NULL,
                              edition = NULL,
                              reference_date = NULL) {
  if (nrow(candidates) > 1) {
    possible_geographies <- unique(candidates$geography)
    possible_editions <- sort(unique(candidates$edition))
    possible_years <- sort(unique(candidates$reference_date))
    cli::cli_abort(c(
      "x" = "The combination of arguments {.code edition = {nullchar(edition)}}
      and {.code reference_date = {nullchar(reference_date)}} does not uniquely
      identify an ASGS {geography} geography.",
      "i" = "Specify edition, reference date or both.",
      " " = "Possible {geography} edition: {possible_editions}",
      " " = "Possible {geography} reference date: {possible_years}"))
  }
}
