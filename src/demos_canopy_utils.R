# Title     : demographics_canopy_utils.R
# Objective : functions to make maps displaying various demographic and
#             canopy values across census areas (tract or block group)
# Created by: Charlotte
# Created on: 15 Feb 2021

#TO Do:
#Add legends?

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

#helper function to make labels for each census area (hard-coded value types)
make_labels <- function(demo, canopy){
  labels <- sprintf(
    "<strong>Geo ID: %s</strong>
    <br/>%g percent canopy cover
    <br/>%g percent open plantable land
    <br/>%g total population
    <br/>%g population density
    <br/>%g percent not white
    <br/>%g percent in poverty
    <br/>%g canopy cover per person
    <br/>%g canopy cover per person in poverty",
    canopy$geo_id, canopy$pct_canopy,
    canopy$pct_open_plantable, demo$tot_pop_race,
    demo$pop_density,
    demo$pct_nonwhite, demo$pct_in_poverty,
    demo$can_pop, demo$can_pov
  ) %>% lapply(htmltools::HTML)

  return(labels)
}

# helper function to make basic map with hard-coded demographic and canopy
# value types
make_map_basic <- function(demo, canopy,labels){
    #make color ramp for each demo/canopy value type
    qpal <- leaflet::colorQuantile(
        palette = "RdPu",
        domain = demo$pct_nonwhite, n=7)
    qpal_can <- leaflet::colorQuantile(
        palette = "YlGn",
        domain = canopy$pct_canopy, n=7)
    qpal_openplant <- leaflet::colorQuantile(
        palette = "GnBu",
        domain = canopy$pct_open_plantable, n=7)
    qpal_pov <- leaflet::colorQuantile(
        palette = "YlOrRd",
        domain = demo$pct_in_poverty, n=7)
    qpal_can_pov <- leaflet::colorQuantile(
        palette = "YlOrRd",
        domain = demo$can_pov, n=7)
    qpal_density <- leaflet::colorQuantile(
        palette = "Greys",
        domain = demo$pop_density, n=7)
    qpal_can_pop <- leaflet::colorQuantile(
        palette = "Greys",
        domain = demo$can_pop, n=7)

    #make map with colored polygons for each value type + census area
    map <- demo$geometry %>% leaflet() %>%
        # Base groups
        addProviderTiles("CartoDB.Positron")%>%
        #addProviderTiles("CartoDB.Positron", group = 'blank')%>%
        # Overlay groups
        addPolygons(color = qpal_can_pop(demo$can_pop) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "canopy cover per person",
                    label = labels
        )%>%
        addPolygons(color = qpal_can_pov(demo$can_pov) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "canopy cover per person in poverty",
                    label = labels
        )%>%
        addPolygons(color = qpal(demo$pct_nonwhite) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "percent not white",
                    label = labels
        )%>%
        addPolygons(color = qpal(demo$pct_nonwhite) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "percent not white",
                    label = labels
        )%>%
        addPolygons(color = qpal_pov(demo$pct_in_poverty) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "percent in poverty",
                    label = labels
        )%>%
        addPolygons(color = qpal_density(demo$pop_density) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "population density",
                    label = labels
        )%>%
        addPolygons(color = qpal_openplant(canopy$pct_open_plantable) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "percent open plantable land",
                    label = labels
        )%>%
        addPolygons(data = canopy$geometry,
                    color = qpal_can(canopy$pct_canopy) ,
                    weight=1,
                    smoothFactor=0.5,
                    opacity=1.0,
                    fillOpacity=0.5,
                    group = "percent canopy cover",
                    label = labels
        )

    return(map)
}

# with this map type, only one layer (demo/canopy value type) is displayed
# at one time
make_base_groups <- function(demo, canopy, map_name){
  #make labels for each census area
  labels <- make_labels(demo, canopy)
  #make basic map
  map <- make_map_basic(demo, canopy, labels)
  #add layer control to map
  map <- map%>%
    addLayersControl(
      baseGroups = c(#"canopy cover",
        "percent canopy cover",
        "percent open plantable land",
        "population density",
        "percent not white",
        "percent in poverty",
        "canopy cover per person",
        "canopy cover per person in poverty"),
      options = layersControlOptions(collapsed = FALSE)
    )
  # save to file
  htmlwidgets::saveWidget(map, file = map_name, selfcontained=TRUE)
    return(map)
}

# with this map type, several layers (demo/canopy value type) can be layered
# together
make_overlay_groups <- function(demo, canopy, map_name){
    #make labels for each census area
    labels <- make_labels(demo, canopy)
    #make basic map
    map <- make_map_basic(demo, canopy, labels)
    #add layer control to map
    map <- map%>%
        addLayersControl(
            overlayGroups = c(#"canopy cover",
                "percent canopy cover",
                "percent open plantable land",
                "population density",
                "percent not white",
                "percent in poverty",
                "canopy cover per person",
                "canopy cover per person in poverty"),
            options = layersControlOptions(collapsed = FALSE)
        )
    # save to file
    htmlwidgets::saveWidget(map, file = map_name, selfcontained=TRUE)
    return(map)
}
