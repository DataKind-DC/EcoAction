library(dplyr)
library(sf)
library(sp)
library(readr)



################################################################################
# Read csv files ---------------------------------------------------------------
################################################################################

read_demographics_block_group_csv <- function() {
  #' Read data/demographics/demographics_block_group.csv
  #'
  #' See data/description_of_data.md for details
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = 'data/demographics/demographics_block_group.csv',
    col_types = readr::cols(
      geo_id = col_character()
    ))
}

read_demographics_tract_csv <- function() {
  #' Read data/demographics/demographics_tract.csv
  #'
  #' See data/description_of_data.md for details
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = 'data/demographics/demographics_tract.csv',
    col_types = readr::cols(
      geo_id = col_character()
    ))
}

read_demographics_civic_association_csv <- function() {
  #' Read data/demographics/demographics_civic_association.csv
  #'
  #' See data/description_of_data.md for details
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = 'data/demographics/demographics_civic_association.csv',
    col_types = readr::cols(
      civ_name = col_character(),
      geo_id = col_character()
    ))
}

read_land_area_block_group_csv <- function() {
  #' Read data/land_area/land_area_block_group.csv
  #'
  #' See data/description_of_data.md for details
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = 'data/land_area/land_area_block_group.csv',
    col_types = readr::cols(
      geo_id = col_character()
    ))
}

read_land_area_tract_csv <- function() {
  #' Read data/land_area/land_area_tract.csv
  #'
  #' See data/description_of_data.md for details
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = 'data/land_area/land_area_tract.csv',
    col_types = readr::cols(
      geo_id = col_character()
    ))
}

read_land_area_civic_association_csv <- function() {
  #' Read data/land_area/land_area_tract.csv
  #'
  #' See data/description_of_data.md for details
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = 'data/land_area/land_area_civic_association.csv',
    col_types = readr::cols(
      civ_name = col_character(),
      geo_id = col_character()
    ))
}

read_tree_data <- function() {
  #' Read "data/tree_data_consolidated - trees.csv"
  #'
  #' Also converts the columns "long" and "lat" into a single "geography" column
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = "data/tree_data_consolidated - trees.csv",
    col_types = readr::cols(
      .default = col_character(),
      row = col_integer(),
      year = col_integer(),
      tree_num = col_integer(),
      tree_count = col_double(),
      lat = col_double(),
      long = col_double()
    )
  ) %>%
    sf::st_as_sf(
      coords = c("long", "lat"),
      crs = "+proj=longlat +datum=WGS84 +no_defs",
      agr = "constant",
      stringsAsFactors = FALSE,
      remove = TRUE
    )
}

read_tree_data_subset <- function() {
  #' Return a subset of the columns from read_tree_data()
  #'
  #' Return year, tree_count, tree_name, scientific_name, and geometry
  #'
  #' @returns tibble DataFrame
  dplyr::select(
    read_tree_data(),
    "year",
    "tree_count",
    "tree_name",
    "scientific_name",
    "geometry",
  )
}

read_block_group_area_in_civics_csv <- function() {
  #' Return tibble of 'data/block_group_area_in_civics.csv'
  #'
  #' @returns tibble DataFrame
  readr::read_csv(
    file = 'data/block_group_area_in_civics.csv',
    col_types = readr::cols(
      geo_id = col_character()
    )
  )
}

################################################################################
# Read shp (shape) files -------------------------------------------------------
################################################################################

read_shp_file <- function(file_path) {
  # TODO: Add doc string.
  sf::st_read(file_path) %>%
    sf::st_transform(sp::CRS("+proj=longlat +datum=WGS84 +no_defs")) %>%
    sf::st_make_valid() # TODO: Is this necessary?
}


# READ SHAPE FILES FROM data/shape_files/Geos ---------------------------
# TODO: make this function
# sort_and_reset_index <- function(df, sort_on) {
#   df <- df[order(df$sort_on)] # Ugh. R.
# }

read_geos_block_group <- function() {
  # TODO: Add doc string
  cbg <- read_shp_file("data/shape_files/Geos/Census_Block_Groups_2010_Polygons")
  cbg <- cbg[, (names(cbg) %in% c("FULLBLOCKG", "geometry"))]
  colnames(cbg) <- c("geo_id", "geometry")
  cbg <- cbg[order(cbg$geo_id),]
  row.names(cbg) <- NULL
  cbg
}

read_geos_tract <- function() {
  # TODO: Add doc string
  tract <- read_shp_file("data/shape_files/Geos/Census_Tract_2010_Polygons")
  tract <- tract[, (names(tract) %in% c("FULLTRACTI", "geometry"))]
  colnames(tract) <- c("geo_id", "geometry")
  tract <- tract[order(tract$geo_id),]
  row.names(tract) <- NULL
  tract
}

read_geos_civ_assoc <- function() {
  tryCatch(
    ca <- read_shp_file("data/shape_files/Modified_Civic_Associations"),
    error = function(e) {
      stop(
        paste0(
          conditionMessage(e),
          "\nHave you pulled and unzipped Modified_Civic_Associations.zip?"
        ),
        call. = FALSE
      )
    }
  )
  ca <- ca[, (names(ca) %in% c("CIVIC", "GIS_ID", "modified", "geometry"))]
  colnames(ca) <- c("civ_name", "geo_id", "modified", "geometry")
  ca <- ca[order(ca$civ_name),]
  row.names(ca) <- NULL
  ca
}

read_geos_civ_assoc_original <- function() {
  ca <- read_shp_file("data/shape_files/Geos/Civic_Association_Polygons")
  ca <- ca[, (names(ca) %in% c("CIVIC", "GIS_ID", "geometry"))]
  colnames(ca) <- c("civ_name", "geo_id", "geometry")
  ca <- ca[order(ca$civ_name),]
  row.names(ca) <- NULL
  ca
}


# READ SHAPE FILES FROM data/shape_files/Tree_Canopy ---------------------------
read_canopy_2008 <- function() {
  read_shp_file("data/shape_files/Tree_Canopy/Tree_Canopy_2008_Polygons")
}

read_canopy_2011 <- function() {
  read_shp_file("data/shape_files/Tree_Canopy/Tree_Canopy_2011_Polygons")
}

read_canopy_2016 <- function() {
  read_shp_file("data/shape_files/Tree_Canopy/Tree_Canopy_2016_Polygons")
}


# READ SHAPE FILES FROM data/shape_files/Land_Types ----------------------------
read_land_alleys <- function() {
  read_shp_file("data/shape_files/Land_Types/Alleys_Polygons")
}

read_land_buildings <- function() {
  read_shp_file("data/shape_files/Land_Types/Buildings_Polygons")
}

read_land_driveways <- function() {
  read_shp_file("data/shape_files/Land_Types/Driveways_Polygons")
}

read_land_ramps <- function() {
  read_shp_file("data/shape_files/Land_Types/Handicap_Ramps_Polygons")
}

read_land_parking <- function() {
  read_shp_file("data/shape_files/Land_Types/Parking_Lots_Polygons")
}

read_land_paved_medians <- function() {
  read_shp_file("data/shape_files/Land_Types/Paved_Medians_Polygons")
}

read_land_ponds <- function() {
  read_shp_file("data/shape_files/Land_Types/Ponds")
}

read_land_roads <- function() {
  read_shp_file("data/shape_files/Land_Types/Roads")
}

read_land_sidewalks <- function() {
  read_shp_file("data/shape_files/Land_Types/Sidewalks_Polygons")
}

read_land_zoning <- function() {
  read_shp_file("data/shape_files/Land_Types/Zoning_Polygons")
}


################################################################################
# Aggregating functions --------------------------------------------------------
################################################################################

# TODO: Make separate functions for block_group and civic_association
# load_geo_data_for_map <- function(geography) {
#   #' Combine all relevant data at the tract or block_group level
#   #'
#   #' Combine read_demographics_subset(), read_land_area_csv(), and the polygons
#   #'  from read_geos_tract() or read_geos_block_group()
#   #'
#   #' @param geography must be either "tract" or "block_group"
#   #'
#   #' @returns tibble DataFrame
#   check_geography(geography)
#   df <- read_demographics_subset(geography) %>%
#     dplyr::left_join(read_land_area_csv(geography), by = "geo_id")
#
#   if (geography == "tract") {
#     df <- dplyr::left_join(df, read_geos_tract(), by = "geo_id")
#   } else if (geography == "block_group") {
#     df <- dplyr::left_join(df, read_geos_block_group(), by = "geo_id")
#   }
#   df
# }













