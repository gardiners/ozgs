#' The three CSV files that form the basis of this dataset were produced by the
#' Australian Bureau of statistics and are used under Creative Commons
#' Attribution 4.0 International (CC BY 4.0) with the following citation:
#'
#' Australian Bureau of Statistics (Jul2021-Jun2026), [Data services and
#' APIs](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/data-services-and-apis),
#' ABS Website, accessed 17 March 2024.

library(readr)
library(dplyr)
library(purrr)
library(stringr)

services_files <- c("1" = "data-raw/20240317_edition-1-2011.csv",
                    "2" = "data-raw/20240317_edition-2-2016.csv",
                    "3" = "data-raw/20240317_edition-3-2021.csv")

services_raw <- services_files |>
  map(read_csv,
      skip = 2,
      col_names = c("structure_name", "asgs_geography", "reference_date","url"),
      col_type = cols(
        .default = col_character(),
        reference_date = col_integer()
      )) |>
  list_rbind(names_to = "edition")

services <- services_raw |>
  mutate(geography = str_extract(asgs_geography,
                                 r"((?<=\()[:upper:]+[:digit:]?)")) |>
  select(geography,
         edition,
         reference_date,
         description = asgs_geography,
         url)

usethis::use_data(services, overwrite = TRUE, internal = TRUE)
