gen_getter_code <- function(geography_name) {
  cat(
    stringr::str_glue('
#\' @eval autodoc("{geography_name}")
{stringr::str_to_lower(geography_name)} <- new_getter("{geography_name}")\n\n'
    )
  )
}
