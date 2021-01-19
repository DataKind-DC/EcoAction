library(dplyr)
library(sf)
library(readr)

# Read csv files ---------------------------------------------------------------
read_demo_can <- function() {
  # TODO: ADd doc string
  readr::read_csv(
    file = "data/demographics_and_canopy.csv",
    col_types = readr::cols(
      geo_id = col_character()
    ))
}

read_demo_can.subset <- function() {
  dplyr::select(
    read_demo_can(),
    "geo_id",
    "pct_nonwhite",
    "pct_canopy"
  )
}

read_tree_data <- function() {
  readr::read_csv(
    file = "data/tree_data_consolidated - trees.csv",
    col_types = readr::cols(
      row = col_integer(),
      year = col_integer(),
      address = col_character(),
      zipcode = col_character(),
      address_clean = col_character(),
      group_name = col_character(),
      cross_street = col_character(),
      planting_location = col_character(),
      app_type = col_character(),
      geocode_confidence = col_character(),
      address_clean_method = col_character(),
      tree_name_orig = col_character(),
      season = col_character(),
      tree_num = col_integer(),
      tree_name = col_character(),
      scientific_name = col_character(),
      tree_count = col_double(),
      lat = col_double(),
      long = col_double()
    )
  )
}

read_tree_data.subset <- function() {
  dplyr::select(
    read_tree_data(),
    "year",
    "tree_count",
    "tree_name",
    "scientific_name",
    "lat",
    "long",
  )
}


# Read shp (shape) files -------------------------------------------------------

read_shp_file <- function(file_path) {
  # TODO: Add doc string.
  sf::st_read(file_path) %>%
    sf::st_transform(
      crs = 3857,
      proj4string = "+proj=longlat +datum=WGS84 +no_defs") %>%
    sf::st_make_valid() # TODO: Is this necessary?
}

read_canopy_shp <- function() {
  read_shp_file("data/shape_files/Tree_Canopy_2016_Polygons")
}

read_cbg_shp <- function() {
  # TODO: Add doc string
  cbg <- read_shp_file("data/shape_files/Census_Block_Groups_2010_Polygons")
  cbg[, (names(cbg) %in% c("FULLBLOCKG", "geometry"))]
}

read_civ_assoc_shp <- function() {
  ca <- read_shp_file("data/shape_files/Civic_Association_Polygons")
  ca[, (names(ca) %in% c("CIVIC", "COLOR", "GIS_ID", "geometry"))]
}











