# Title     : Most Likely Civic Associations
# Objective : For each block group and tract, calculate the most likely civic association
# Created on: 2/14/21

library(sf)


source("src/load_data.R")

civ <- read_geos_civ_assoc()
bg <- read_geos_block_group()
tr <- read_geos_tract()

# Use the SF package to find the percentage of each civic association in each
#   block_group and tract

# You'll probably want to use sf::st_union() and sf::st_area()



# Save the result in a CSV, perhaps with the format
# geo_id, civ_1, civ_1_pct, civ_2, civ_2_pct, civ_3, civ_3_pct

