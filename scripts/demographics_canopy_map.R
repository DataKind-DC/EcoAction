# Title     : demographics_canopy_maps.R
# Objective : compare demographics at census tract level with tree equity
# Created by: Charlotte
# Created on: 7 Feb 2021

#Remaining questions:
# Total population of different categories aren't the same? which to use?
# Remove census areas that are over cemetery and airport?

#TO DO:
#Get neighborhood names for tract instead of geo_id
#make more generalizable and less hard coded
#add canopy coverage as layer (got error when tried to, maybe too large)
#Check which libraries are needed

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

#get data and functions
#setwd('Path_to/EcoAction')
source("src/load_data.R")
source("src/demos_canopy_utils.R")
#separately, map demography per area or population and canopy cover per area

#For tracts-get demographics, canopy, and make map
#get demographics
demo_tract <- read_demographics_tract_csv()
#get canopy area
canopy_tract <- read_land_area_tract_csv()
#read geos of tracts and add to demo_tract and canopy_tract
tracts <- read_geos_tract()
#add geometry
demo_tract <- merge(demo_tract, tracts, by="geo_id")
canopy_tract <- merge(canopy_tract, tracts, by="geo_id")

#add population density to demo_tract
demo_tract$pop_density = demo_tract$tot_pop_race/canopy_tract$area_m_sq

#equity measures: canopy area by person and canopy area by person in poverty
demo_tract$can_pop = canopy_tract$area_canopy/demo_tract$tot_pop_race
demo_tract$can_pov = canopy_tract$area_canopy/demo_tract$pop_in_poverty

#make maps with different demographic and canopy values for each
#tract (can overlay layers in secon map)
tract_demo_canopy_base <- make_base_groups(demo_tract, canopy_tract, 'tract_demo_canopy_base.html')
tract_demo_canopy_overlay <- make_overlay_groups(demo_tract, canopy_tract, 'tract_demo_canopy_overlay.html')

#pairwise plots
corr_df = data.frame(demo_tract$pct_in_poverty, demo_tract$pct_nonwhite,
               canopy_tract$pct_plantable, canopy_tract$pct_open_plantable,
               canopy_tract$pct_canopy)
pairs(corr_df, pch=18)

#make same maps at block_group level (smaller than tracts)
#get demographics
demo_bg <- read_demographics_block_group_csv()
#get canopy area
canopy_bg <- read_land_area_block_group_csv()
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

#make maps with different demographic and canopy values for each
#block group (can overlay layers in secon map)
bg_demo_canopy_base <- make_base_groups(demo_bg, canopy_bg, 'bg_demo_canopy_base.html')
bg_demo_canopy_overlay <- make_overlay_groups(demo_bg, canopy_bg, 'bg_demo_canopy_overlay.html')

#pairwise graphs comparing some different values in each block group
corr_df = data.frame(demo_bg$pct_in_poverty, demo_bg$pct_nonwhite,
                     canopy_bg$pct_plantable, canopy_bg$pct_open_plantable,
                     canopy_bg$pct_canopy)
pairs(corr_df, pch=18)

plot(demo_bg$pct_in_poverty, canopy_bg$pct_canopy, pch=18)
