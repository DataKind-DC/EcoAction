library(dplyr)
library(sf)

source("src/load_data.R")
source("src/sf_helpers.R")

# Calculate Tree Canopy Percentage ---------------------------------------------


int_df <- area_of_top_on_base(read_geos_block_group(), read_canopy_2016()) %>%
  dplyr::rename(c(
    "area_canopy16" = "area_top",
    "pct_canopy16" = "pct_top"
  ))
write.csv(int_df, "data/canopy16_block_group.csv", row.names = FALSE)

int_df <- area_of_top_on_base(read_geos_tract(), read_canopy_2016()) %>%
  dplyr::rename(c(
    "area_canopy16" = "area_top",
    "pct_canopy16" = "pct_top"
  ))
write.csv(int_df, "data/canopy16_tract.csv", row.names = FALSE)




