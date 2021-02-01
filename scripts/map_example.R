# Title     : TODO
# Objective : TODO
# Created by: <your_name_here>
# Created on: <date>

library(leaflet)

source("src/load_data.R")

geography <- "block_group" # Must be "block_group" or "tract"
data_df <- load_geo_data_for_map("tract")

# Make fancy maps!
