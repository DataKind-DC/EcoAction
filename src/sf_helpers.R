library(sf)
library(dplyr)
library(magrittr)
library(areal)

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


fix_sf_agr_error <- function(sf) {
    #' Fixes sf renaming problems
    sf %>%
        dplyr::mutate()
}


interpolate_bg_to_ca <- function(bg_sf, bg_id, ca_sf, ca_id, weight = "sum",
                                 extensive, intensive, output = "tibble") {
    #' Performs areal weighted interpolation (ensuring correct CRS)
    #'
    #' @param bg_sf A block group sf object with data to be interpolated
    #' @param bg_id Unique block group identifier (most likely 'geo_id')
    #' @param ca_sf A civic association sf object that data should be interpolated to
    #' @param ca_id Unique civic association identifier
    #' @params see areal::aw_interpolate() for on remaining parameter details

    # identify all variables of interest (extensive or intensive)
    if (missing(extensive)) {
        var_interpolate <- intensive
    } else if (missing(intensive)) {
        var_interpolate <- extensive
    } else {
        var_interpolate <- union(extensive, intensive)
    }

    #### Change CRS for math ####
    # capture input CRS (to revert)
    ca_crs <- sf::st_crs(ca_sf)

    # force projected CRS (same version used by Google Maps/OSM)
    bg_merc <- sf::st_transform(bg_sf, "EPSG:3857")
    ca_merc <- sf::st_transform(ca_sf, "EPSG:3857")

    ##############################

    # Validate inputs (return test results on failure)
    if (!isTRUE(areal::ar_validate(bg_merc, ca_merc, var_interpolate))) {
        stop(
            "Input does not pass validation\n",
            # print dataframe showing checks in error
            areal::ar_validate(
                bg_merc, ca_merc,
                var_interpolate,
                verbose = TRUE
            ) %>%
                as.data.frame() %>%
                print() %>%
                capture.output() %>%
                paste0(collapse = "\n"),
            call. = FALSE
        )
    }

    ca_interp <- areal::aw_interpolate(
        .data = ca_merc,
        tid = {{ ca_id }},
        source = bg_merc,
        sid = {{ bg_id }},
        weight = weight,
        output = output,
        extensive = extensive,
        intensive = intensive
    )

    if(!missing(output) && output == "sf") {
        sf::st_transform(ca_interp, crs = ca_crs)
    } else {
        ca_interp
    }
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
