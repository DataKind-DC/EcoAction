# original author: Rich Carder
# date: March 31, 2020

library(dplyr)
library(tidyverse)
library(tidycensus)

source("src/load_data.R")

# BEFORE RUNNING THIS SCRIPT ---------------------------------------------------
# 1. Get a census apikey from https://api.census.gov/data/key_signup.html
# 2. Insert apikey into the line below, run the line, and restart R
# census_api_key(key="<insert_key_here>", install=TRUE, overwrite = TRUE)


# Get Demographic Data ---------------------------------------------------------
# Extract ACS 5-year estimates at the block group (or any larger
# geography) using the tidycensus package.


create_demographics_csv <- function(geography, file_name) {
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
create_demographics_csv("tract", "data/demographics_tract.csv")
create_demographics_csv("block group", "data/demographics_block_group.csv")


# Income and language-spoken data not available at block level

# dec_vars_df <- tidycensus::load_variables(2010, "sf1", cache = TRUE)
#
# df <- get_decennial(
#   geography = "block",
#   variables = unname(dem_vars_v),
#   # table = NULL,
#   # cache_table = FALSE,
#   year = 2010,
#   sumfile = "sf1",
#   state = "Virginia",
#   county = "Arlington County",
#   geometry = FALSE,
#   output = "tidy",
#   keep_geo_vars = FALSE,
#   shift_geo = FALSE,
#   summary_var = NULL,
#   key = NULL,
#   show_call = FALSE
# )
