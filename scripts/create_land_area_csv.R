library(dplyr)
library(sf)

source("src/load_data.R")
source("src/sf_helpers.R")

# Calculate Tree Canopy Percentage ---------------------------------------------


land_areas_and_pcts <- function(base_df) {
  base_df$area_m_sq <- sf::st_area(base_df$geometry)

  top <- read_canopy_2016()
  base_df$area_canopy <- area_of_top_on_base(base_df, top)
  base_df <- dplyr::mutate(base_df, pct_canopy = area_canopy / area_m_sq * 100)

  print('Calculating area of plantable_mpoly on each polygon of base_df')
  top <- readRDS('data/rds/plantable_mpoly.rds')
  base_df$area_plantable <- area_of_top_on_base(base_df, top)
  base_df <- dplyr::mutate(base_df, pct_plantable = area_plantable / area_m_sq * 100)

  print('Calculating area of open_plantable_mpoly on each polygon of base_df')
  top <- readRDS("data/rds/open_plantable_mpoly.rds")
  base_df$area_open_plantable <- area_of_top_on_base(base_df, top)
  base_df <- dplyr::mutate(base_df, pct_open_plantable = area_open_plantable / area_m_sq * 100)

  dplyr::select(tibble::as_tibble(base_df), -geometry)
}


base_df <- read_geos_tract()
df <- land_areas_and_pcts(base_df)
write.csv(df, "data/land_area/land_area_tract.csv", row.names = FALSE)

# This took ~30 min on a 2.5GHz MacBook Pro with 16GB RAM
base_df <- read_geos_civ_assoc()
df <- land_areas_and_pcts(base_df)
write.csv(df, "data/land_area/land_area_civic_association.csv", row.names = FALSE)

# This one took three hours to run!
base_df <- read_geos_block_group()
df <- land_areas_and_pcts(base_df)
write.csv(df, "data/land_area/land_area_block_group.csv", row.names = FALSE)

