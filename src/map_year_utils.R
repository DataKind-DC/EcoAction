# Title     : map_year_utils.R
# Objective : function for make map of trees planted per year
# Created by: Charlotte
# Created on: 15 Feb 2021
# Updated   : 30 Mar 2021, J. Allen Baron

library(tidyverse)
library(leaflet)
library(RColorBrewer)
library(htmltools)
library(htmlwidgets)
library(sf)
library(raster)
library("rgdal")
library(units)
library(lwgeom)
library(ggplot2)


year_map <- function(to_map, map_name) {
    #' Create leaflet map of trees planted by year with legend
    #'
    #' @param to_map data for mapping
    #' @param map_name [optional] path to save map to, if specified

    #color for map
    factpal <- leaflet::colorFactor(topo.colors(10), to_map$year)

    #include name of tree and year planted on label
    labels <- sprintf_as_HTML(
        "<strong>%s</strong><br/>%s<br/>Planted: %g",
        to_map$tree_name, to_map$scientific_name, to_map$year
    )


    # Map each tree planted, color-coded by year
    lf <- to_map %>%
        leaflet::leaflet() %>%
        leaflet::addProviderTiles("CartoDB.Positron") %>%
        leaflet::addCircles(
            color = ~factpal(year) ,
            weight = 1,
            radius = 25,
            opacity = 1.0,
            fillOpacity = 0.5,
            label = labels
        ) %>%
        leaflet::addLegend(
            'bottomright',
            pal = factpal,
            values = ~year,
            title = 'Year',
            opacity = 1
        )

    # save to file
    if (!missing(map_name)) {
        htmlwidgets::saveWidget(lf, file = map_name, selfcontained = TRUE)
    }

    lf
}


year_layer_map <-function(to_map, map_name){
    #' Create leaflet map with checkboxes to (de)select trees planted by year
    #'
    #' @param to_map data for mapping
    #' @param map_name [optional] path to save map to, if specified

    #one layer per year
    years <- sort(unique(to_map$year))

    lf <- to_map %>%
        leaflet::leaflet() %>%
        leaflet::addProviderTiles("CartoDB.Positron")

    for (i in seq_along(years)) {
        yr_data <- dplyr::filter(to_map, year == years[i])

        lf <- lf %>%
            leaflet::addCircles(
                data =  yr_data$geometry,
                color = "forestgreen",
                weight = 0.5,
                radius = 25,
                opacity = 0.5,
                fillOpacity = 0.5,
                label = sprintf_as_HTML(
                    "<strong>%s</strong><br/>%s<br/>Planted: %g",
                    yr_data$tree_name,
                    yr_data$scientific_name,
                    yr_data$year
                ),
                group = years[i]
            )
    }

    # added title based on https://stackoverflow.com/questions/49072510/r-add-title-to-leaflet-map
    tag.map.title <- tags$style(
        HTML(
            ".leaflet-control.map-title {
            transform: translate(-50%,20%);
            position: fixed !important;
            left: 50%;
            text-align: center;
            padding-left: 10px;
            padding-right: 10px;
            background: rgba(255,255,255,0.75);
            font-weight: bold;
            font-size: 24px;
            }"
        )
    )

    title <- tags$div(
        tag.map.title, HTML("Trees Planted by Year")
    )

    lf <- lf %>%
        # Layers control
        leaflet::addLayersControl(
            overlayGroups = years,
            options = layersControlOptions(collapsed = FALSE)
        ) %>%
        leaflet::addControl(
            html = title,
            position = "topleft",
            className = "map-title"
        )

    # save to file
    if (!missing(map_name)) {
        htmlwidgets::saveWidget(lf, file = map_name, selfcontained = TRUE)
    }

    lf
}


sprintf_as_HTML <- function(fmt, ...) {
    #' Vectorized conversion of sprintf output as HTML
    #'
    #' See sprintf for arguments and details

    formatted <- sprintf(fmt, ...)
    as_HTML <- purrr::map(formatted, htmltools::HTML)

    as_HTML
}
