# Title     : TODO
# Objective : TODO
# Created by: <your_name_here>
# Created on: <date>

library(leaflet)

source("src/load_data.R")

# Demographics and canopy data (only available at block_group and tract level)
geography <- "block_group" # Must be "block_group" or "tract"
data_df <- load_geo_data_for_map("tract") # #FIXME: need to update this function

# For civic assocations, you'll need to use this
# civ_assoc <- read_geos_civ_assoc()

# Trees planted by EcoAction -------------
planted_trees <- read_tree_data_subset()

# Make fancy maps! -----------------


