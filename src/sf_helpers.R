library(sf)
library(dplyr)
library(magrittr)

rm_not_2dim <- function(sf_df) {
    #' Removes non-polygons (i.e. not 2-dimensional
    #'
    #' @param sf_df an sf data.frame
    sf_df[sf::st_dimension(sf_df) == 2, ]
}

add_poly_area <- function(sf_df) {
    #' Add area of shapes to sf_df
    #'
    #' @inheritParams rm_non_polygons
    dplyr::mutate(sf_df, area = sf::st_area(sf_df))
}

get_poly_with_area <- function(sf_df) {
    #' Get polygons with area (drop everything else)
    #'
    #' @inheritParams rm_non_polygons
    sf_df %>%
        rm_not_2dim %>%
        add_poly_area
}


area_of_top_on_base <- function(base_df, top_df) {
    # Units in m^2
    # TODO: docstring
    top_mpoly <- sf::st_union(top_df)
    int <- tibble::as_tibble(sf::st_intersection(base_df, top_mpoly))
    int$area_int <- sf::st_area(int$geometry) # Units of m^2

    # Some clunky code to handle when there is no intersection in a poly of base_df
    df <- dplyr::left_join(tibble::as_tibble(base_df), int, by = "geo_id")
    df <- df$area_int
    df[is.na(df)] <- 0
    df
}