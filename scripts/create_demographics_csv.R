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


# Define Function to calculate percentages ---------------------------------------------
calc_demographics_pct <- function(df) {
  dplyr::mutate(
    df,
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
    pct_not_hisp = pop_not_hisp / tot_pop_hisp * 100,
    pct_in_poverty = pop_in_poverty / tot_pop_income * 100,
  )
}

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
  acs_df <- calc_demographics_pct(acs_df)

  # Fill nans with 0
  acs_df[is.na(acs_df)] <- 0

  write.csv(acs_df, file_name, row.names = FALSE)
  print(paste("Wrote ACS 5-yr data data to", file_name))
}

# acs_vars_df <- tidycensus::load_variables(2019, "acs5", cache = TRUE)
create_acs_demographics_csv("tract", "data/demographics/demographics_tract.csv")
create_acs_demographics_csv("block group", "data/demographics/demographics_block_group.csv")


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
# Use areal interpolation from `areal` pkg to estimate statistics for
# civic associations from block groups

create_demographics_civ_assoc_csv <- function() {
  #' Use interpolate_bg_to_ca to interpolate extensive variables from block
  #' group to civic association, then calculate percentages

  # DEFINE Variables for interpolation
  vars_to_interpolate <- c(
    # race
    "tot_pop_race", "pop_white", "pop_nonwhite", "pop_black", "pop_native",
    "pop_asian", "pop_pac_isl", "pop_other", "pop_two_plus",
    # ethinicity
    "tot_pop_hisp", "pop_hisp", "pop_not_hisp",
    # income
    "tot_pop_income", "pop_in_poverty", "per_cap_income"
  )

  # Combine demographics with shapefile data
  bg_geo <- read_geos_block_group()
  bg_dem <- read_demographics_block_group_csv()
  bg_geo_dem <- bg_geo %>%
    full_join(bg_dem, by = "geo_id")

  ca_geo <- read_geos_civ_assoc() %>%
    fix_sf_agr_error() # fixes rename.sf error

  # Complete interpolation
  civ_dem_df <- interpolate_bg_to_ca(
    bg_geo_dem,
    geo_id,
    ca_geo,
    geo_id,
    weight = "sum",
    extensive = vars_to_interpolate,
    output = "tibble"
  )

  # Calculate demographic percentages for civic associations
  civ_dem_df <- civ_dem_df %>%
    calc_demographics_pct()

  write.csv(civ_dem_df, 'data/demographics/demographics_civic_association.csv', row.names = FALSE)
}

create_demographics_civ_assoc_csv()
