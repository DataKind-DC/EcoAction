# original author: Rich Carder
# date: March 31, 2020

library(dplyr)
library(tidyverse)
library(tidycensus)
library(units)

source("src/load_data.R")
source("src/sf_helpers.R")

# BEFORE RUNNING THIS SCRIPT ---------------------------------------------------
# 1. Get a census apikey from https://api.census.gov/data/key_signup.html
# 2. Insert apikey into the line below, run the line, and restart R
# census_api_key(key="<insert_key_here>", install=TRUE, overwrite = TRUE)


# Get ACS Demographic Data -----------------------------------------------------
# Extract ACS 5-year estimates at the block group (or any larger
# geography) using the tidycensus package.


create_acs_demographics_csv <- function(geography, file_name) {
  # TODO: Do we need age and/or language stats?
  dem_vars_v <- c(
    "tot_pop_race" = "B02001_001", # Tot pop for use in RACE variables
    "pop_white" = "B02001_002",
    "pop_black" = "B02001_003",
    "pop_native" = "B02001_004",
    "pop_asian" = "B02001_005",
    "pop_pac_isl" = "B02001_006",
    "pop_other" = "B02001_007",
    "pop_two_plus" = "B02001_008",
    "tot_pop_hisp" = "B03002_001", # Tot pop for HISP vars
    "pop_not_hisp" = "B03002_002",
    "pop_white_not_hisp" = "B03002_003",
    "pop_hisp" = "B03002_012",
    "tot_pop_income" = "B17021_001", # Tot pop for INCOME vars
    "pop_in_poverty" = "B17021_002",
    "per_cap_income" = "B19301_001"

    # "tot_pop_lang" = "B16001_001", # Only returns nans
    # "pop_eng_only" = "B16001_002",
    # "pop_spanish" = "B16001_003",
    # "pop_french" = "B16001_006",
    # "pop_chinese" = "B16001_075",
    # "pop_spanish_low_eng" = "B16001_005"
  )

  acs_df <- tidycensus::get_acs(
    geography = geography,
    variables = unname(dem_vars_v),
    year = 2019,
    survey = "acs5",
    state = "Virginia",
    county = "Arlington County",
    geometry = FALSE
  ) %>%
    dplyr::select(-moe, -NAME)  # Drop "measurement of error" and "NAME" columns

  # Pivot table so that acs variables become column headers
  acs_df <- tidyr::spread(acs_df, key = "variable", value = "estimate")

  # Rename acs variables to hooman understandable names
  acs_df <- dplyr::rename(acs_df, tidyselect::all_of(dem_vars_v))
  acs_df <- dplyr::rename(acs_df, c("geo_id" = "GEOID"))

  # Calculate percentages
  acs_df <- dplyr::mutate(
    acs_df,
    pop_nonwhite = tot_pop_race - pop_white,
    pct_white = pop_white / tot_pop_race * 100,
    pct_nonwhite = 100 - pct_white,
    pct_black = pop_black / tot_pop_race * 100,
    pct_asian = pop_asian / tot_pop_race * 100,
    pct_pac_isl = pop_pac_isl / tot_pop_race * 100,
    pct_native = pop_native / tot_pop_race * 100,
    pct_other = pop_other / tot_pop_race * 100,
    pct_two_plus = pop_two_plus / tot_pop_race * 100,
    pct_hisp = pop_hisp / tot_pop_hisp * 100,
    pct_white_not_hisp = pop_white_not_hisp / tot_pop_hisp * 100,
    # pct_nonwhitenh = 100 - pct_white_not_hisp,
    pct_in_poverty = pop_in_poverty / tot_pop_income * 100,
  )

  # Fill nans with 0
  acs_df[is.na(acs_df)] <- 0

  write.csv(acs_df, file_name, row.names = FALSE)
  print(paste("Wrote ACS 5-yr data data to", file_name))
}

# acs_vars_df <- tidycensus::load_variables(2019, "acs5", cache = TRUE)
create_acs_demographics_csv("tract", "data/demographics_tract.csv")
create_acs_demographics_csv("block group", "data/demographics_block_group.csv")


# Create CSV of how much area of each block group is in each civic assoc -------

create_block_group_area_in_civics_csv <- function(min_m2_threshold = 10) {

  civics_df <- read_geos_civ_assoc()
  blocks_df <- read_geos_block_group()

  # Calculate area in m^2 for each block group and save to df
  bg_areas <- tibble(get_poly_with_area(blocks_df))
  bg_areas <- subset(bg_areas, select = -geometry)

  # I know for-loops are bad practice in R, but I couldn't figure it out otherwise.
  # For each civic association...
  for (row in 1:nrow(civics_df)) {
    civ_name <- civics_df[row,]$civ_name
    civ_geo <- civics_df[row,]$geometry

    # Get a column of the area of each block group that intersects with
    # the area of the civic assoc
    areas_b_groups_on_civ <- tibble(drop_units(area_of_top_on_base(blocks_df, civ_geo)))
    # I assume that tiny areas are just polygon errors. Thus, set everything
    # below 'min_m2_threshold' to zero.
    areas_b_groups_on_civ[areas_b_groups_on_civ < min_m2_threshold] <- 0

    # Add this column to bg_areas
    bg_areas[, ncol(bg_areas) + 1] <- areas_b_groups_on_civ
    # Name the column the name of the civic association
    colnames(bg_areas)[ncol(bg_areas)] <- paste0(civ_name)
  }

  write.csv(bg_areas, 'data/block_group_area_in_civics.csv', row.names = FALSE)
}

create_block_group_area_in_civics_csv()


# Estimate Civic Association Demographic Data ----------------------------------
# Use the pct of area of each block group to estimate statistics for
# civic associations

create_demographics_civ_assoc_csv <- function() {

  bg_areas <- readr::read_csv(
    file = 'data/block_group_area_in_civics.csv',
    col_types = readr::cols(
      geo_id = col_character()
    )
  )

  # This is a df where the cells are the percentage of the area of the block
  # group (rows) in each civic association (columns).
  bg_areas_pct <- select(bg_areas, -geo_id, -area) / bg_areas$area

  bg_dem_df <- dplyr::select(read_demographics_csv('block_group'),
                             "geo_id",
                             "tot_pop_race",
                             "pop_nonwhite",
                             "tot_pop_income",
                             "pop_in_poverty"
  )

  # Initialize a df for the civic associations demographic data
  civ_df <- tibble(read_geos_civ_assoc())
  civ_dem_df <- select(civ_df, -geometry)

  # First, for each civic association, multiply the tot_pop_race count in the
  # block group with the percentage of the block group that is in that civic
  # association. (This is not perfect because we don't know the density variation
  # in the block groups, but it should a decent approximation.)
  # Then, squash the columns to give a single value for each civic
  # association
  civ_dem_df$tot_pop_race <- colSums(bg_areas_pct * bg_dem_df$tot_pop_race)

  # Do the same thing for each demographic category
  civ_dem_df$pop_nonwhite <- colSums(bg_areas_pct * bg_dem_df$pop_nonwhite)
  civ_dem_df$tot_pop_income <- colSums(bg_areas_pct * bg_dem_df$tot_pop_income)
  civ_dem_df$pop_in_poverty <- colSums(bg_areas_pct * bg_dem_df$pop_in_poverty)

  civ_dem_df <- mutate(
    civ_dem_df,
    pct_nonwhite = pop_nonwhite / tot_pop_race * 100,
    pct_in_poverty = pop_in_poverty / tot_pop_income * 100,
  )

  write.csv(civ_dem_df, 'data/demographics_civic_associations.csv', row.names = FALSE)
}

create_demographics_civ_assoc_csv()