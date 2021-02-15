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
    labels <- sprintf(
        "<strong>%s</strong><br/>%s<br/>planted: %g",
        to_map$tree_name, to_map$scientific_name, to_map$year
    ) %>% lapply(htmltools::HTML)


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
    saveWidget(lf, file = map_name, selfcontained=TRUE)
    lf

}

#each year is it's own, stackable layer in this map
year_layer_map <-function(to_map, map_name){
    #one layer per year
    years = sort(unique(to_map$year))
    label_groups = c()
    for (i in 1:10) {
        label_groups[i]=paste("Trees planted in", years[i])
    }
    #CAN THIS BE DONE WITH FOR LOOP?
    lf <- to_map %>%
        leaflet() %>%
        addProviderTiles("CartoDB.Positron") %>%
        addCircles( data =  to_map[ which(to_map$year==years[1]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[1]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[1]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[1]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[1]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[2]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[2]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[2]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[2]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[2]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[3]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[3]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[3]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[3]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[3]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[4]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[4]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[4]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[4]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[4]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[5]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[5]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[5]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[5]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[5]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[6]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[6]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[6]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[6]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[6]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[7]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[7]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[7]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[7]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[7]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[8]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[8]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[8]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[8]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[8]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[9]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[9]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[9]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[9]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[9]
        )%>%
        addCircles( data =  to_map[ which(to_map$year==years[10]),"geometry"],
                    color = "forestgreen",
                    weight=0.5,
                    radius = 25,
                    opacity=0.5,
                    fillOpacity=0.5,
                    label = sprintf(
                        "<strong>%s</strong><br/>%s<br/>planted: %g",
                        to_map[ which(to_map$year==years[10]),"tree_name"]$tree_name,
                        to_map[ which(to_map$year==years[10]),"scientific_name"]$scientific_name,
                        to_map[ which(to_map$year==years[10]),"year"]$year
                    ) %>% lapply(htmltools::HTML),
                    group = label_groups[10]
        )%>%
        # Layers control
        addLayersControl(
            overlayGroups = label_groups,
            options = layersControlOptions(collapsed = FALSE)
        )

    # save to file
    saveWidget(lf, file = map_name, selfcontained=TRUE)
    lf
}
