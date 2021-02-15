# Title     : map_year.R
# Objective : Make maps of trees planted by Eco Arlington per year
# Created by: Charlotte
# Created on: 7 Feb 2021

#TO DO: make some tree planted per census area map?

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


#get data and functions
#setwd('Path_to/EcoAction')
source("src/load_data.R")
source("src/map_year_utils.R")
trees_sf <- read_tree_data_subset()
#if you get "'data/tree_data_consolidated - trees.csv' does not exist in
#current working directory" error, ensure you've gotten file from google drive

#for better labeling add jitter to points. This means it is possible to see
#labels of trees at the same exact location.
#note that this means the locations of trees is no longer exact
trees_sf_jitter <- trees_sf
trees_sf_jitter$geometry <- st_jitter(trees_sf_jitter$geometry,
                                      amount = 0.0001, factor = 0.0001)

#make map without jitter
ym <- year_map(trees_sf, "map_trees_by_year.html")
ylm <- year_layer_map(trees_sf, "map_trees_layer_by_year.html")

#make map with jitter
ym_jitter <- year_map(trees_sf_jitter, "map_trees_jitter_by_year.html")
ylm_jitter <- year_layer_map(trees_sf_jitter, "map_trees_jitter_layer_by_year.html")


#histogram plots to better understand year and tree type patterns
#number of trees planted each year
y <-hist(trees_sf$year)
#number of trees planted by type of tree, color-coded by year planted
year_type <-trees_sf%>%
    group_by(year)%>%
    count(tree_name)
year_type_plot <- ggplot(year_type, aes(fill=year, y=n, x=tree_name)) +
    geom_bar(position="stack", stat="identity")
year_type_plot + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

