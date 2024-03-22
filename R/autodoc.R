autodoc <- function(geography_name){
  descr <- with(services, description[geography == geography_name][1])
  c(
    stringr::str_glue("@title {descr}"),
    stringr::str_glue("@description Fetch ASGS geometries for {descr}."),
    "@details",
    "The following combinations of ASGS `edition` and `reference_date` are available:",
    service_tbl(geography_name),
    "",
    "@inheritParams get_geography",
    "@export"
  )
}

service_tbl <- function(geography_name) {
  services |>
    dplyr::filter(geography == geography_name) |>
    dplyr::select(geography, edition, reference_date) |>
    dplyr::arrange(reference_date) |>
    knitr::kable(format = "pipe",
                 col.names = c("**`geography`**",
                               "**`edition`**",
                               "**`reference_date`**"))
}
