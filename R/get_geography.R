#' Get a geography from the ASGS web service
#'
#' `get_geography()` downloads and caches the geometries and data defined by a
#' specified ASGS geography, with optional filtering using SQL or spatial
#' queries.
#'
#' @param geography The name of the ASGS geography to download. Valid choices
#'   are `r cli::pluralize("{sort(unique(services$geography))}")`.
#' @param identifier An optional character vector of named features to download
#'   from the specified geography. For most ASGS geographies, these are
#'   human-friendly names like e.g. "Tasmania" (a feature within the STE
#'   geography), "Sydney" (a feature within the LGA geography) or "2150" (a
#'   feature within the POA geography). If specified, `identifier` takes
#'   precedence over `where`. If neither `identifier` nor `where` are specified,
#'   all of the features in the specified geography will be downloaded.
#' @param edition An ASGS edition: `1`, `2`, or `3`.
#' @param reference_date The geography's year of release. For most geographies,
#'   `reference_year` is optional and specifying an `edition` will be
#'   sufficient. However, for LGAs, CEDs and SEDs, the ASGS contains multiple
#'   releases per edition. For these geographies, a `reference_date` must be
#'   supplied to uniquely identify a release.
#' @param layer One of:
#'  - `"gen"`, the default. Fetches simplified geometries that have been
#'   generalised to 0.000025° or 2.5m.
#'  - `"full"`, full ASGS geometries. Identical to ASGS Shapefile and Geopackage
#'   downloads.
#'  - `"point"`, point geometries for each records in a geography.
#' @param where An optional SQL WHERE clause to filter the features returned by
#'   the request. Ignored if `identifier` is specified.
#' @param filter_geom An optional [`sf::sfc`] or single `sf` geometry to filter
#'   the records returned by the request.
#' @param predicate An optional spatial predicate to specify the relation
#'   between `filter_geom` and `geography`. One of `"intersects"`, `"contains"`,
#'   `"crosses"`, `"overlaps"`, `"touches"`, and `"within"`.
#' @param cache A `cachem`-compatible cache. If not otherwise specified,
#'   defaults to a memory cache. To persistently store downloaded ASGS
#'   geometries and data, supply an object created by [cachem::cache_disk()].
#' @param ... Additional arguments passed to [arcgislayers::arc_read()].
#'
#' @return Returns a `sf` spatial data frame with geometry and data for the
#'   requested ASGS geography.
#' @export
get_geography <- function(geography,
                          identifier = NULL,
                          edition = NULL,
                          reference_date = NULL,
                          layer = c("gen", "full", "point"),
                          where = NULL,
                          filter_geom = NULL,
                          predicate = c("intersects", "contains", "crosses",
                                        "overlaps", "touches", "within"),
                          cache = getOption("ozgs.cache"),
                          ...) {
  geography <- match.arg(geography, unique(services$geography))
  layer <- match.arg(layer)
  furl <- get_service_url(geography, edition, reference_date, layer)

  # Construct a WHERE clause from feature identifiers
  if (!is.null(identifier)) {
    if (!is.null(where)) {
      cli::cli_warn("Arguments {.code identifier} and {.code where} were both
                    specified. The value of {.code where} will be ignored.")
    }
    where <- build_where(identifier,
                         get_id_field(geography, edition, reference_date))
  }


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

get_service_url <- function(geography, edition, reference_date, layer) {
  url_suffix <- switch(layer,
                       "gen" = "/1",
                       "full" = "/0",
                       "point" = "/2")
  candidates <- get_service(geography, edition, reference_date)
  check_specificity(candidates, geography, edition, reference_date)
  paste0(candidates$url, url_suffix)
}

get_service <- function(geography, edition, reference_date) {
  services[geography %maybe% services$geography &
             edition %maybe% services$edition &
             reference_date %maybe% services$reference_date,]
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

#' Determine the identifier field for a geography
#'
#' @inheritParams get_geography
#'
#' @return A character string naming the identifier field.
#' @noRd
get_id_field <- function(geography, edition, reference_date) {
  service <- get_service(geography, edition, reference_date)
  service$identifier_raw[1]
}

#' Prepare a WHERE clause for use in arcgislayers::arc_select()
#'
#' @param identifier A character vector of feature identifiers (e.g. names like
#'   "Sydney" or "New South Wales")
#' @param id_field The geography-specific field used to refer to a feature by
#'   name (e.g. for ASGS3 STEs, "STATE_NAME_2021")
#'
#' @return A character string for use as a `where` argument.
#' @noRd
build_where <- function(identifier, id_field) {
  identifier <- stringr::str_glue("'{identifier}'")
  stringr::str_glue("{id_field} IN ({stringr::str_flatten_comma(identifier)})")
}
