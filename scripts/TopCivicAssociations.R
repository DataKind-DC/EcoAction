# Title     : TopCivicAssociation.R
# Objective : compute demographics and canopy info for civic associations
#             make maps for top (or bottom) k civic associations for
#             indices of interest
# Created by: Charlotte
# Created on: 10 April 2021

#get libraries
library(tidyverse)
library(leaflet)
library(RColorBrewer)
library(htmltools)
library(htmlwidgets)
library(sf)
library(sp)
library(raster)
library("rgdal")
library(units)
library(lwgeom)

#get data and functions
setwd('Path_to/EcoAction')
source("src/demos_canopy_utils_civicassociation.R")
source("src/load_data.R")
source("src/topCivAssociations.R")

#find demographics for civic association (weighted average) using block group
#because those are smaller
#for now using bg canopy too but shouldn't have to?

civ <- read_geos_civ_assoc()
civ_names <- read.csv('data/civ_names.csv')
civ <- merge(civ, civ_names, by="civ_name")


#get demographics
demo_bg <- read_demographics_csv('block_group')
#get canopy area
canopy_bg <- read_land_area_csv('block_group')
#read geos of bgs and add to demo_bg and canopy_bg
block_group <- read_geos_block_group()
#merge bgs with geometries
demo_bg <- merge(demo_bg, block_group, by="geo_id")
canopy_bg <- merge(canopy_bg, block_group, by="geo_id")

#add population density to demo_bg
demo_bg$pop_density = demo_bg$tot_pop_race/canopy_bg$area_m_sq

#equity measures: canopy area by person and canopy area by person in poverty
demo_bg$can_pop = canopy_bg$area_canopy/demo_bg$tot_pop_race
demo_bg$can_pov = canopy_bg$area_canopy/demo_bg$pop_in_poverty

#change format and get columns of interest for civic assoication
demo_for_civ <- st_sf(data.frame(demo_bg$pop_white,demo_bg$pop_black, demo_bg$pop_native,
                                 demo_bg$pop_asian, demo_bg$pop_pac_isl, demo_bg$pop_other,
                                 demo_bg$pop_two_plus, demo_bg$pop_not_hisp, demo_bg$pop_white_not_hisp,
                                 demo_bg$pop_hisp, demo_bg$tot_pop_income, demo_bg$pop_in_poverty,
                                 demo_bg$tot_pop_race, demo_bg$tot_pop_hisp,
                                 demo_bg$geometry))
colnames(demo_for_civ)<-c("pop_white", "pop_black", "pop_native", "pop_asian",
                          "pop_pac_isl","pop_other", "pop_two_plus", "pop_not_hisp",
                          "pop_white_not_hisp","pop_hisp","tot_pop_income","pop_in_poverty",
                          "tot_pop_race", "tot_pop_hisp",
                          "geometry")
#Look at warning message
demo_civ <- st_interpolate_aw(demo_for_civ, civ, extensive = TRUE)
demo_civ$tot_pop_race <- demo_civ$pop_asian+demo_civ$pop_black+demo_civ$pop_native+
  demo_civ$pop_asian+demo_civ$pop_pac_isl+demo_civ$pop_other+demo_civ$pop_two_plus
demo_civ$tot_pop_hisp <- demo_civ$pop_hisp+demo_civ$pop_not_hisp

#get percents
demo_civ <- dplyr::mutate(
  demo_civ,
  pct_white = pop_white / tot_pop_race * 100,
  pct_nonwhite = 100 - pct_white,
  pct_black = pop_black / tot_pop_race * 100,
  pct_asian = pop_asian / tot_pop_race * 100,
  pct_pac_isl = pop_pac_isl / tot_pop_race * 100,
  pct_native = pop_native / tot_pop_race * 100,
  pct_other = pop_other / tot_pop_race * 100,
  pct_two_plus = pop_two_plus / tot_pop_race * 100,
  pct_hisp = pop_hisp / tot_pop_hisp * 100,
  pct_white_not_hisp = pop_white_not_hisp / tot_pop_hisp * 100,
  # pct_nonwhitenh = 100 - pct_white_not_hisp,
  pct_in_poverty = pop_in_poverty / tot_pop_income * 100,
)
demo_civ$geo_id <-civ$civ_name
demo_civ$abv <-civ$abv

#get canopy info from block groups
canopy_for_civ<-st_sf(data.frame(canopy_bg$area_m_sq, canopy_bg$area_canopy,
                                 canopy_bg$area_plantable, canopy_bg$area_open_plantable,
                                 canopy_bg$geometry))
colnames(canopy_for_civ)<-c("area_m_sq","area_canopy", "area_plantable",
                            "area_open_plantable", "geometry")
canopy_civ <- st_interpolate_aw(canopy_for_civ, civ, extensive = TRUE)
#get percents
canopy_civ <- dplyr::mutate(
  canopy_civ,
  pct_canopy = area_canopy / area_m_sq * 100,
  pct_platanble = area_plantable / area_m_sq * 100,
  pct_open_plantable = area_open_plantable / area_m_sq * 100,
)
#get abbreviations of civic association for easier visualization
canopy_civ$geo_id <-civ$civ_name
canopy_civ$abv <-civ$abv

#add population density to demo_civ
demo_civ$pop_density = demo_civ$tot_pop_race/canopy_civ$area_m_sq

#equity measures: canopy area by person and canopy area by person in poverty
demo_civ$can_pop = canopy_civ$area_canopy/demo_civ$tot_pop_race
demo_civ$can_pov = canopy_civ$area_canopy/demo_civ$pop_in_poverty


#make maps with different demographic and canopy values for each
#civic group (can overlay layers in second map)
civ_demo_canopy_base <- make_base_groups(demo_civ, canopy_civ, 'civ', 'civ_demo_canopy_base.html')
civ_demo_canopy_overlay <- make_overlay_groups(demo_civ, canopy_civ, 'civ', 'civ_demo_canopy_overlay.html')

hist(demo_civ$pct_in_poverty, breaks = 20)
hist(canopy_civ$pct_open_plantable, breaks=20)
hist(canopy_civ$pct_canopy, breaks=20)

corr_df = data.frame(demo_civ$pct_in_poverty, canopy_civ$pct_open_plantable,
                     canopy_civ$pct_canopy)
pairs(corr_df, pch=18)

#get number of trees planted per civic association
trees_sf <- read_tree_data_subset()
numTrees <- st_intersects( civ$geometry, trees_sf$geometry)
for(i in 1:length(numTrees)){
    canopy_civ$numTrees[i] = length(numTrees[[i]])
}
#get some more indices that mgiht be of interest
canopy_civ$TreesPerSqm <- canopy_civ$numTrees/canopy_civ$area_m_sq
canopy_civ$TreesPerPerson <- canopy_civ$numTrees/demo_civ$tot_pop_race
canopy_civ$TreesPerPov <- canopy_civ$numTrees/demo_civ$pop_in_poverty

#get top 10 civic assocations for pct poverty, area open plantable,
#pop density, pct canopy cover
#Eco Arlington # trees planted per person

#make some maps
topK_colored(demo_civ, 10, TRUE, "pct_in_poverty", "Pov_colored")
topK_binary(demo_civ, 10, TRUE, "pct_in_poverty", "Pov_binary")

topK_colored(canopy_civ, 10, FALSE, "pct_canopy", "Can_colored")
topK_binary(canopy_civ, 10, FALSE, "pct_canopy","Can_binary")

topK_colored(canopy_civ, 10, TRUE, "pct_open_plantable", "Plantable_colored")
topK_binary(canopy_civ, 10, TRUE, "pct_open_plantable","Plantable_binary")

topK_colored(demo_civ, 10, TRUE, "pop_density", "PopDens_colored")
topK_binary(demo_civ, 10, TRUE, "pop_density","PopDens_binary")

topK_colored(canopy_civ, 10, FALSE, "TreesPerSqm", "TreeDens_colored")
topK_binary(canopy_civ, 10, FALSE, "TreesPerSqm","TreeDens_binary")

topK_colored(canopy_civ, 10, FALSE, "TreesPerPerson", "TreePop_colored")
topK_binary(canopy_civ, 10, FALSE, "TreesPerPerson","TreePop_binary")
