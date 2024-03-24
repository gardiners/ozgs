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
      col_names = c("structure_name", "description", "reference_date","url"),
      col_type = cols(
        .default = col_character(),
        reference_date = col_integer()
      )) |>
  list_rbind(names_to = "edition")

# Extract ASGS geography name acronyms for use as identifiers:
services <- services_raw |>
  mutate(geography = str_extract(description,
                                 r"((?<=\()[[:upper:]/]+[:digit:]?)")) |>
  select(geography,
         edition,
         reference_date,
         description,
         url)

# The 3rd edition uses "S/T" as the acronym for the "State and Territory"
# geography, where the 1st and 2nd editions use "STE". For consistency (and
# because `s/t()` isn't a syntactic function name), make the "S/T" geography
# accessible with the synonym "STE", as well as by "S/T":
ste_synonym <- services |>
  filter(geography == "S/T") |>
  mutate(geography = "STE")
services <- bind_rows(services, ste_synonym) |>
  arrange(edition, reference_date, geography)

usethis::use_data(services, overwrite = TRUE, internal = TRUE)
