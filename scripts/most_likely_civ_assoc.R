# Title     : Most Likely Civic Associations
# Objective : For each block group and tract, calculate the most likely civic association
# Created on: 2/14/21

library(sf)
library(dplyr)
library(magrittr)
library(units)

source("src/load_data.R")
source("src/sf_helpers.R")

# logic helper
all_duplicated <- function(x) {
    #' Identify all duplicates
    #'
    #' @param vector
    duplicated(x) | duplicated(x, fromLast = TRUE)
}


# load data
civ <- read_geos_civ_assoc()
bg <- read_geos_block_group()
tr <- read_geos_tract()


# Split block groups that cross civic association boundaries
#   Prior to split could maybe use sf::st_overlaps() to identify block groups
#   to split (and avoid a bunch of lines/points being created?)

# IMPORTANT NOTE: sf::st_intersection() output differs depending on order of
#   input; this should not be the case! QGIS doesn't have this issue.

bg_civ <- sf::st_intersection(bg, civ) %>%
    # sf::st_cast(to = "POLYGON")
    get_poly_with_area()

civ_bg <- sf::st_intersection(civ, bg) %>%
    dplyr::mutate(., area = sf::st_area(.)) %>%
    dplyr::filter(area != units::set_units(0, "m^2"))

# NOTE 2: This approach creates a bunch of lines and small polygons where there
#   is minimal overlap with a civic association; these should be dropped/ignored
#   but not sure how. Possible approach with sf::st_cast(bg_civ, to = "POLYGON")

# Probably want to merge small block groups into neighbors within the civic
#   association, making sure they are a reasonable size

## calculate reasonable size (reasonable = area within interquartile range?)
bg_area <- sf::st_area(bg)
bg_iq <- quantile(bg_area, c(0.25, 0.75))


## Identify candidate split block groups that might need to be merged
bg_to_merge <- bg_civ %>%
    filter(all_duplicated(geo_id) & area < bg_iq[1])





## Identify neighbors to split bg within the civic association

# Using intersection to identify lines where neighbors overlap; may not be
#   best approach; use sf::st_touches()?; centroid distance better?;
neighbor_intersect <- sf::st_intersection(bg_civ)
neighbor_lines <- neighbor_intersect[sf::st_dimension(neighbor_intersect) == 1, ]

neighbor_within_civ <- # need code





# Save the result in a CSV, perhaps with the format
# geo_id, civ_name, pct_in_civ (pct of bg in this civic association),
#   pct_of_civ (pct of civic association this

