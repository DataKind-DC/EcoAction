# Title     : Create Plantable MultiPolygon RDS
# Created by: brent
# Created on: 1/30/21

# Create `data/rds/plantable_mpoly.rds` and `data/rds/open_plantable_mpoly.rds`
# 1. Filter out all non-residential areas from the the zoning polygons
# 2. Combine all impermeable land shapes into a single multipolygon.
# 3. Remove the imperiable land from the housing areas to get `plantable_mpoly`
# 4. Remove canopy polygon from plantable_mpoly to get `open_plantable_mpoly`

library(sf)

source("src/load_data.R")
source("src/leaflet_helpers.R")

zones_sf <- read_land_zoning()

# Generate the plantable_zone_names list with the line below
# sort(unique(as_tibble(zones_sf)$LABEL))

# Comment out all zones that include housing
plantable_zone_names <- c(
  "Apartment Dwelling and Commercial District",
  "Apartment Dwelling District",
  "C-O-CRYSTAL CITY",
  "C-O-ROSSLYN",
  "Columbia Pike - Form Based Code District",
  "Commercial Off. Bldg, Hotel and Apartment District",
  "Commercial Off. Bldg, Hotel and Multiple-Family Dwelling",
  "Commercial Office Building, Hotel and Apartment District",
  # "Commercial Redevelopment District",
  "Commercial Town House District",
  # "General Commercial District",
  # "Hotel District",
  # "Light Industrial District",
  # "Limited Commercial - Professional Office Building District",
  # "Limited Industrial District",
  # "Local Commercial District",
  "Mixed Use-Virginia Square",
  "Multiple-Family Dwelling and Hotel District",
  "One Family Residential-Town-House Dwelling District",
  "One-Family Dwelling District",
  "One-Family, Restricted Two Family Dwelling District",
  # "Public Service District",
  "Residential Town House Dwelling District",
  # "Restricted Local Commercial District",
  # "Service Commercial - Community Business Districts",
  # "Service Industrial District",
  # "Special Development District",
  # "Special District"
  "Two-Family and Town House Dwelling District"
)

# Get multipoly of just the areas that are plantable for EcoAction
plantable_sf <- zones_sf[zones_sf$LABEL %in% plantable_zone_names,]
plantable_mpoly <- sf::st_union(plantable_sf)
# quick_map(plantable_mpoly, "plantable_zones")

# Load all impermeable areas
land_sf_list <- list(
  read_land_alleys(),
  read_land_driveways(),
  read_land_parking(),
  read_land_paved_medians(),
  read_land_ponds(),
  read_land_ramps(),
  read_land_sidewalks(),
  read_land_roads(),
  read_land_buildings()
)

# TODO: Use Apply and then Reduce instead of a for loop
# THIS CODE IS UNTESTED
# Combine all unplantable areas into a single multipoly object
# tmp <- apply(sf::st_union, land_sf_list)
# t <- Reduce(sf::st_union, tmp)
# plantable_mpoly <- sf::st_difference(plantable_mpoly, t)

# Iteratively combine impermeable land_sf into single poly, then remove from plantable_mpoly
for (land_sf in land_sf_list) {
  land_u <- sf::st_union(land_sf)
  plantable_mpoly <- sf::st_difference(plantable_mpoly, land_u)
}

saveRDS(plantable_mpoly, "data/rds/plantable_mpoly.rds")
quick_map(plantable_mpoly, "plantable_area")


################################################################################
# Remove canopy from plantable_mpoly to make "plantable and open"
################################################################################

plantable_mpoly <- readRDS("data/rds/plantable_mpoly.rds")
canopy <- read_canopy_2016()
canopy_mpoly <- sf::st_union(canopy)

open_plantable_mpoly <- sf::st_difference(plantable_mpoly, canopy_mpoly)
saveRDS(open_plantable_mpoly, "data/rds/open_plantable_mpoly.rds")

# Run this line at your own risk. It took like 30 min on my machine and created
#   a 232 MB html file
# quick_map(open_plantable_mpoly, "open_plantable")



