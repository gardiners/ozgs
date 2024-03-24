#' Generate documentation for a geography-specific 'getter'
#'
#' @param geography_name Character string name of an ASGS geography, as defined
#'   in the internal dataset `services$geography`.
#'
#' @return A character vector of Roxygen2 documentation for the geograpgy.
#'
#' @noRd
rd_autodoc <- function(geography_name){
  asgs_geography <- latest_metadata(geography_name, "asgs_geography")
  asgs_description <- latest_metadata(geography_name, "description") |>
    clean_description()

  c(
    stringr::str_glue("@title {asgs_geography}"),
    stringr::str_glue(
      "@description Fetch ASGS geometries for the **{asgs_geography}** geography."),
    "@details",
    asgs_description,
    "",
    "@section Availability:",
    "The following combinations of ASGS `edition` and `reference_date` are available:",
    rd_service_tbl(geography_name),
    "",
    "@inheritParams get_geography",
    "@export"
  )
}

#' For a given geography, generate a table of ASGS editions and years for which
#' the geography is available
#'
#' @inheritParams autodoc
#'
#' @return A character string containing a markdown table.
#'
#' @noRd
rd_service_tbl <- function(geography_name) {
  services |>
    dplyr::filter(geography == geography_name) |>
    dplyr::select(geography, edition, reference_date) |>
    dplyr::arrange(reference_date) |>
    knitr::kable(format = "pipe",
                 col.names = c("**`geography`**",
                               "**`edition`**",
                               "**`reference_date`**"))
}

#' Use metadata from the most recent release of a geography.
#'
#' Early editions of the ASGS web service do not consistently have content in
#' the their metadata fields. For example, ASGS1 does not provide any content
#' via the 'Description' field in its ArcGIS MapServers.
#'
#' @inheritParams autodoc
#' @param field The field in `services` from which to retrieve content.
#'
#' @return A character string containing the content from `services[field]` for
#'   the most recent `reference_date` for the given `geography_name`.
#'
#' @noRd
latest_metadata <- function(geography_name, field) {
  services |>
    dplyr::filter(geography == geography_name) |>
    dplyr::arrange(desc(reference_date)) |>
    dplyr::slice_head(n = 1) |>
    dplyr::pull({{field}})
}

clean_description <- function(description) {
  description |>
    stringr::str_replace_all(
      pattern = c(
        r"(<DIV STYLE="text-align:Left;font-size:12pt"><P><SPAN>The Australian Statistical Geography Standard \(ASGS\) provides users with an integrated set of standard regions that they can use to analyse and integrate statistics produced by the ABS and other organisations. )" = "",
        "</SPAN></P></DIV>" = "",
        r"(Australian Statistical Geography Standard \(ASGS\) Edition 3\nhttps://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026)"  =
          "[Australian Statistical Geography Standard (ASGS) Edition 3](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026)",
        "\n" = "\n\n")) |>
    stringr::str_split_1("\n")
}
