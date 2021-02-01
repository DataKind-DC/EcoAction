library(dplyr)
library(sf)

source("src/load_data.R")

# Calculate Tree Canopy Percentage ---------------------------------------------

area_of_top_on_base <- function(base_df, top_df) {
  # Units in m^2
  # TODO: docstring
  top_mpoly <- sf::st_union(top_df)
  int <- tibble::as_tibble(sf::st_intersection(base_df, top_mpoly))
  int$area_int <- sf::st_area(int$geometry) # Units of m^2

  # Some clunky code to handle when there is no intersection in a poly of base_df
  df <- dplyr::left_join(tibble::as_tibble(base_df), int, by = "geo_id")
  df <- df$area_int
  df[is.na(df)] <- 0
  df
}


land_areas_and_pcts <- function(base_df) {
  # TODO: docstring
  base_df$area_m_sq <- sf::st_area(base_df$geometry)

  top <- read_canopy_2016()
  base_df$area_canopy <- area_of_top_on_base(base_df, top)
  base_df <- dplyr::mutate(base_df, pct_canopy = area_canopy / area_m_sq * 100)

  top <- readRDS('data/rds/plantable_mpoly.rds')
  base_df$area_plantable <- area_of_top_on_base(base_df, top)
  base_df <- dplyr::mutate(base_df, pct_plantable = area_plantable / area_m_sq * 100)

  top <- readRDS("data/rds/open_plantable_mpoly.rds")
  base_df$area_open_plantable <- area_of_top_on_base(base_df, top)
  base_df <- dplyr::mutate(base_df, pct_open_plantable = area_open_plantable / area_m_sq * 100)

  dplyr::select(tibble::as_tibble(base_df), -geometry)
}


base_df <- read_geos_tract()
df <- land_areas_and_pcts(base_df)
write.csv(df, "data/land_area_tract.csv", row.names = FALSE)

# This one took three hours to run!
base_df <- read_geos_block_group()
df <- land_areas_and_pcts(base_df)
write.csv(df, "data/land_area_block_group.csv", row.names = FALSE)

