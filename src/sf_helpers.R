library(sf)
library(dplyr)

area_of_top_on_base <- function(base_df, top_df) {
  # TODO: docstring

  int <- sf::st_intersection(top_df, base_df)
  int <- tibble::as_tibble(int) # TODO: Is this needed?

  int$area_int <- sf::st_area(int$geometry) # Units of m^2

  tmp <- int %>% # TODO: Clean this up, tmp vars are not great
    dplyr::group_by(geo_id) %>%
    dplyr::summarise(area_top = sum(area_int))

  base_df <- tibble::as_tibble(base_df)
  base_df$area <- sf::st_area(base_df$geometry)

  base_df <- dplyr::left_join(base_df, tmp, by = 'geo_id')
  base_df <- dplyr::mutate(base_df, pct_top = area_top / area)
  base_df <- dplyr::select(base_df, c("geo_id", "area", "area_top", "pct_top"))
}