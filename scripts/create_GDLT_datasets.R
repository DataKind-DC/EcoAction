# Objective : Create datasets with all variables of interest
#   identified by EcoAction in 2021-05-04 meeting and rankings for 1) civic
#   associations and 2) block groups.
#
# INCLUDES: [G]eography, [D]emographics, [L]and area, and [T]rees planted.
#
# Created on: 2021-06-04

library(tidyverse)
library(sf)
source("src/load_data.R")
source("src/sf_helpers.R")


# Define dataset building functions ----------------------------------------

create_GDLT_df <- function(geo, vtr_asc, vtr_desc) {
    #' Combines data by `geo_id`, including tree counts and ranks for variables
    #' of interest.
    #'
    #' @param geo geography; one of "block_group" or "civic_association"
    #' @param vtr_asc variables to rank in ascending order
    #' @param vtr_desc variables to rank in descending order

    geo <- match.arg(geo, c("block_group", "civic_association"))

    if (geo == "block_group") {
        geo_sf <- read_geos_block_group()
        dem <- read_demographics_block_group_csv()
        land_area <- read_land_area_block_group_csv()
        tree <- read_tree_data()
    } else if (geo == "civic_association") {
        geo_sf <- read_geos_civ_assoc()
        dem <- read_demographics_civic_association_csv() %>%
            # remove to avoid duplicate columns
            dplyr::select(-civ_name, -modified)
        land_area <- read_land_area_civic_association_csv() %>%
            # remove to avoid duplicate columns
            dplyr::select(-civ_name, -modified)
        tree <- read_tree_data()
    }

    # Add count of trees planted
    geo_trees <- geo_sf %>%
        dplyr::mutate(tree_count = st_count_safe(geo_sf, tree))

    # Join into single dataset
    full_df <- geo_trees %>%
        dplyr::full_join(dem, by = "geo_id") %>%
        dplyr::full_join(land_area, by = "geo_id") %>%
        dplyr::mutate(
            # create ascending rank columns
            dplyr::across(
                .cols = dplyr::one_of(vtr_asc),
                .fns = dplyr::min_rank,
                .names = "rank_{.col}"
            ),
            # create descending rank columns
            dplyr::across(
                .cols = dplyr::one_of(vtr_desc),
                .fns = ~ dplyr::min_rank(desc(.x)),
                .names = "rank_{.col}"
            )
        )

    full_df
}


# Define variables to rank ------------------------------------------------

# Identify vars of interest and rank direction
# For direction: asc = ascending, i.e. low values of greater interest;
#   desc = descending, i.e. high values of greater interest

# NOTE (from Allen): pct_white, pct_not_hisp, and pct_open_plantable were left
#   out because they are redundant
var_rank_asc <- c(
    # income
    "per_cap_income",
    # land area
    "pct_canopy"
)

var_rank_desc <- c(
    # race
    "pct_nonwhite", "pct_black", "pct_asian",
    "pct_pac_isl", "pct_native", "pct_other",
    "pct_two_plus",
    # ethinicity
    "pct_hisp",
    # income
    "pct_in_poverty",
    # land area
    "pct_plantable"
)


# Create & save full GDLT datasets ----------------------------------------

bg_gdlt <- create_GDLT_df("block_group", var_rank_asc, var_rank_desc)
civ_gdlt <- create_GDLT_df("civic_association", var_rank_asc, var_rank_desc)
