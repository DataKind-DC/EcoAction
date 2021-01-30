library(sf)

source("src/load_data.R")
source("src/sf_helpers.R")
source("src/leaflet_helpers.R")

zones_sf <- read_land_zoning()

# Generate the unplantable_zones list with the line below
# sort(unique(as_tibble(zones_sf)$LABEL))

# Comment out all zones that include housing
unplantable_zone_names <- c(
  # "Apartment Dwelling and Commercial District",
  # "Apartment Dwelling District",
  # "C-O-CRYSTAL CITY",
  # "C-O-ROSSLYN",
  # "Columbia Pike - Form Based Code District",
  # "Commercial Off. Bldg, Hotel and Apartment District",
  # "Commercial Off. Bldg, Hotel and Multiple-Family Dwelling",
  # "Commercial Office Building, Hotel and Apartment District",
  "Commercial Redevelopment District",
  # "Commercial Town House District",
  "General Commercial District",
  "Hotel District",
  "Light Industrial District",
  "Limited Commercial - Professional Office Building District",
  "Limited Industrial District",
  "Local Commercial District",
  # "Mixed Use-Virginia Square",
  # "Multiple-Family Dwelling and Hotel District",
  # "One Family Residential-Town-House Dwelling District",
  # "One-Family Dwelling District",
  # "One-Family, Restricted Two Family Dwelling District",
  "Public Service District",
  # "Residential Town House Dwelling District",
  "Restricted Local Commercial District",
  "Service Commercial - Community Business Districts",
  "Service Industrial District",
  "Special Development District",
  "Special District"
  # "Two-Family and Town House Dwelling District"
)

# Get multipoly of just the areas that are unplantable for EcoAction
unplantable_sf <- zones_sf[zones_sf$LABEL %in% unplantable_zone_names,]
unplantable_mpoly <- sf::st_union(unplantable_sf)

# Load all unplantable physical areas
land_sf_list <- list(
  read_land_alleys()
  # read_land_driveways(),
  # read_land_parking(),
  # read_land_paved_medians(),
  # read_land_ponds(),
  # read_land_ramps(),
  # read_land_sidewalks(),
  # read_land_roads(),
  # read_land_buildings()
)

# Combine all unplantable areas into a single multipoly object
for (land_sf in land_sf_list) {
  land_u <- sf::st_union(land_sf)
  unplantable_mpoly <- sf::st_union(unplantable_mpoly, land_u)
}

saveRDS(unplantable_mpoly, 'data/rds/unplantable_mpoly.rds')
quick_map(unplantable_mpoly, "unplantable_area")

# TODO: Also add canopy on top of unplantable_area



