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
