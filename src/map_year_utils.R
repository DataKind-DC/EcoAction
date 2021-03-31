# Title     : map_year_utils.R
# Objective : function for make map of trees planted per year
# Created by: Charlotte
# Created on: 15 Feb 2021

#TO DO:
#Is there a way of making layered map (year_layer_map) with loop?

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

#map trees by year with legend
year_map <- function(to_map, map_name) {
    #color for map
    factpal <- colorFactor(topo.colors(10), to_map$year)

    #include name of tree and year planted on label
    labels <- sprintf_as_HTML(
        "<strong>%s</strong><br/>%s<br/>Planted: %g",
        to_map$tree_name, to_map$scientific_name, to_map$year
    )


    # Map each tree planted, color-coded by year
    lf <- to_map %>%
        leaflet() %>%
        addProviderTiles("CartoDB.Positron") %>%
        addCircles( color = ~factpal(year) ,
                    weight=1,
                    radius = 25,
                    opacity=1.0,
                    fillOpacity=0.5,
                    label = labels
        ) %>%
        addLegend(
            'bottomright',
            pal = factpal, values = ~year,
            title = 'Year',
            opacity = 1
        )

    # save to file
    if (!missing(map_name)) {
        saveWidget(lf, file = map_name, selfcontained = TRUE)
    }

    lf
}

#each year is it's own, stackable layer in this map
year_layer_map <-function(to_map, map_name){
    #one layer per year
    years <- sort(unique(to_map$year))
    label_groups <- paste("Trees planted in", years)

    lf <- to_map %>%
        leaflet() %>%
        addProviderTiles("CartoDB.Positron")

    for (i in seq_along(years)) {
        yr_data <- dplyr::filter(to_map, year == years[i])

        lf <- lf %>%
            addCircles(
                data =  yr_data$geometry,
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity = 0.5,
                    fillOpacity = 0.5,
                    label = sprintf_as_HTML(
                        "<strong>%s</strong><br/>%s<br/>Planted: %g",
                        yr_data$tree_name,
                        yr_data$scientific_name,
                        yr_data$year
                    ),
                    group = label_groups[i]
        )
    }

    lf <- lf %>%
        # Layers control
        addLayersControl(
            overlayGroups = label_groups,
            options = layersControlOptions(collapsed = FALSE)
        )

    # save to file
    if (!missing(map_name)) {
        saveWidget(lf, file = map_name, selfcontained = TRUE)
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
