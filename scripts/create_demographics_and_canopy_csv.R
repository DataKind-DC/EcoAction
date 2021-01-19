# original author: Rich Carder
# date: March 31, 2020

library(dplyr)
library(tidyverse)
library(tidycensus)
library(sf)

# BEFORE RUNNING THIS SCRIPT ---------------------------------------------------
# 1. Unzip data/shape_files/Tree_Canopy_2016_Polygons.zip
# 2. Unzip data/shape_files/Census_Block_Groups_2010_Polygons.zip
# 2. Get a census apikey from https://api.census.gov/data/key_signup.html
# 3. Insert apikey into the line below, run the line, and restart R
# census_api_key(key="<insert_key_here>", install=TRUE, overwrite = TRUE)


# Get Demographic Data ---------------------------------------------------------
# Extract ACS 5-year estimates at the block group (or any larger
# geography) using the tidycensus package.

acs_vars <- tidycensus::load_variables(2019, "acs5", cache = TRUE)

# TODO: Do we need age and/or language stats?
dem_vars <- c(
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
)

acs <- tidycensus::get_acs(
  geography = "block group",
  variables = unname(dem_vars),
  year = 2019,
  survey = "acs5",
  state = "Virginia",
  county = "Arlington County",
  geometry = FALSE
) %>%
  dplyr::select(-moe, -NAME)  # Drop "measurement of error" and "NAME" columns

# Pivot table so that acs variables become column headers
acs <- tidyr::spread(acs, key = "variable", value = "estimate")

# Rename acs variables to hooman understandable names
acs <- dplyr::rename(acs, tidyselect::all_of(dem_vars))
acs <- dplyr::rename(acs, c("geo_id" = "GEOID"))

# Calculate percentages
acs <- dplyr::mutate(
  acs,
  pct_white = pop_white / tot_pop_race,
  pct_nonwhite = 1 - pct_white,
  pct_black = pop_black / tot_pop_race,
  pct_asian = pop_asian / tot_pop_race,
  pct_pac_isl = pop_pac_isl / tot_pop_race,
  pct_native = pop_native / tot_pop_race,
  pct_other = pop_other / tot_pop_race,
  pct_two_plus = pop_two_plus / tot_pop_race,
  pct_hisp = pop_hisp / tot_pop_hisp,
  pct_white_not_hisp = pop_white_not_hisp / tot_pop_hisp,
  # pct_nonwhitenh = 1 - pct_white_not_hisp,
  pct_in_poverty = pop_in_poverty / tot_pop_income,
)


# Calculate Tree Canopy Percentage ---------------------------------------------

read_shape_file <- function(file_path) {
  # TODO: Add doc string. Maybe put in separate file?
  shp <- sf::st_read(file_path) %>%
    sf::st_transform(
      crs = 3857,
      proj4string = "+proj=longlat +datum=WGS84 +no_defs") %>%
    sf::st_make_valid() # TODO: Is this necessary?
}

canopy <- read_shape_file("data/shape_files/Tree_Canopy_2016_Polygons")
cbg <- read_shape_file("data/shape_files/Census_Block_Groups_2010_Polygons")

int <- sf::st_intersection(canopy, cbg)
int <- tibble::as_tibble(int) # TODO: Is this needed?

int$area_int <- sf::st_area(int$geometry) # Units of m^2

tmp <- int %>% # TODO: Clean this up, tmp vars are not great
  dplyr::group_by(FULLBLOCKG) %>%
  dplyr::summarise(area_canopy = sum(area_int))

# TODO: Clean up below and add comments
cbg <- tibble::as_tibble(cbg)
cbg <- dplyr::left_join(cbg, tmp, by = 'FULLBLOCKG')
cbg$area <- sf::st_area(cbg$geometry)
cbg <- dplyr::mutate(cbg, pct_canopy = area_canopy / area)
cbg <- dplyr::rename(cbg, c("geo_id" = "FULLBLOCKG"))
cbg <- dplyr::select(cbg, c("geo_id", "area", "area_canopy", "pct_canopy"))
comb <- dplyr::left_join(acs, cbg, by = 'geo_id')

write.csv(comb, "data/demographics_and_canopy.csv", row.names = FALSE)


# Old Code ---------------------------------------------------------------------

# language <- get_acs(geography = "block group",
#                     variables = c("B16001_001","B16001_002","B16001_003","B16001_004","B16001_005",
#                                   "B16001_075","B16001_006"),
#                     year = 2019, state = "Virginia",county="Arlington County", geometry = FALSE) %>%
#   dplyr::select(-moe) %>%
#   spread(key = "variable", value = "estimate") %>%
#   mutate(
#     tot_population_language=B16001_001,
#     only_english_pct = B16001_002/tot_population_language,
#     any_other_than_english_pct = 1-(B16001_002/tot_population_language),
#     spanish_pct=B16001_003/tot_population_language,
#     french_pct=B16001_006/tot_population_language,
#     chinese_pct=B16001_075/tot_population_language,
#     spanish_with_english_pct=B16001_004/tot_population_language,
#     spanish_no_english_pct=B16001_005/tot_population_language) %>%
#   dplyr::select(-c(NAME))
#
# age <- get_acs(geography = "block group",
#                variables = c(sapply(seq(1,49,1), function(v) return(paste("B01001_",str_pad(v,3,pad ="0"),sep="")))),
#                year = 2019, state = "Virginia",county = "Arlington County", geometry = FALSE)%>%
#   dplyr::select(-moe) %>%
#   spread(key = "variable", value = "estimate") %>%
#   mutate(
#     denom = B01001_001,
#     age_under30_ma = dplyr::select(., B01001_007:B01001_011) %>% rowSums(na.rm = TRUE),
#     # age_25_64_ma = dplyr::select(., B01001_011:B01001_019) %>% rowSums(na.rm = TRUE),
#     age_over65_ma = dplyr::select(., B01001_020:B01001_025) %>% rowSums(na.rm = TRUE),
#     age_under30_fe = dplyr::select(., B01001_031:B01001_035) %>% rowSums(na.rm = TRUE),
#     #age_25_64_fe = dplyr::select(., B01001_035:B01001_043) %>% rowSums(na.rm = TRUE),
#     age_over65_fe = dplyr::select(., B01001_044:B01001_049) %>% rowSums(na.rm = TRUE),
#     age_pct_under30 = (age_under30_ma + age_under30_fe)/denom,
#     #age_pct_25_64 = (age_25_64_ma + age_25_64_fe)/denom,
#     age_pct_over65 = (age_over65_ma + age_over65_fe)/denom
#   ) %>%
#   dplyr::select(-starts_with("B0"))%>%dplyr::select(-ends_with("_ma")) %>% dplyr::select(-ends_with("_fe")) %>% dplyr::select(-denom)

