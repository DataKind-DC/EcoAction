# Neighborhood planted tree density map using leaflet
# 2020-12-17

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

source("src/load_data.R")

# Load data
trees_sf <- read_tree_data_subset()
neigh_sf <- read_civ_assoc_shp()
# neigh_sf <- read_cbg_shp()

#calculate area of neighborhoods
neigh_sf <- neigh_sf %>%
  mutate(area= set_units(st_area(.),mi^2))

#find trees within neighborhood
tree_in_neigh <- st_join(trees_sf, neigh_sf, join=st_within)

# count trees per neighborhood
# TODO: BUG, this should aggregate the "tree_count" for each civ_id
tree_neigh_count <- count(as_tibble(tree_in_neigh), civ_name)

#join tree count with neigh sf, calc tree density
neigh_tree_sf <- left_join(neigh_sf, tree_neigh_count) %>%
  mutate(tree_sq_mi = as.numeric(n/area)) %>%
  print()

#color for map
qpal <- colorQuantile(
  palette = "YlGn",
  domain = neigh_tree_sf$tree_sq_mi, n=7)

# Map
lf <- neigh_tree_sf %>%
  leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(color = ~qpal(tree_sq_mi) ,
              weight=1,
              smoothFactor=0.5,
              opacity=1.0,
              fillOpacity=0.5
  ) %>%
  addLegend(
    'bottomright',
    pal = qpal, values = ~tree_sq_mi,
    title = 'Planted Trees Density',
    opacity = 1
  )

# save to file
saveWidget(lf, file = "map_trees_planted_civ_assoc.html")

