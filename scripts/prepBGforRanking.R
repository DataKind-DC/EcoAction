#prepare Block Group stats for ranking

#libraries
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
#setwd('Path_to/EcoAction')
source("src/load_data.R")

#get blockgroups demo data and canopy data- merge
demo_bg <- read_demographics_block_group_csv()
canopy_bg <- read_land_area_block_group_csv()

bg <- merge(demo_bg, canopy_bg, by.x = "geo_id", by.y="geo_id")


#get number of trees in bg
trees <- read_tree_data()
bg_loc <- read_geos_block_group()
bg_loc$tree_count <- lengths(st_intersects(bg_loc, trees))

bg <- merge(bg, bg_loc, by.x = "geo_id", by.y="geo_id")

bg$tree_area <- bg$tree_count/bg$area_m_sq

#get ranks for each column
df_ranks <- bg

columns <- c('pct_in_poverty', 'pct_nonwhite', 'pct_hisp',
             'pct_canopy', 'pct_open_plantable', 'pct_plantable', 'tree_area')

for (c_name in columns) {
  df_sub <- dplyr::select(bg, geo_id, c_name)
  df_sub_sorted <- df_sub[order(-df_sub[,c_name]),]

  # Add column of rank in
  df_sub_sorted[, ncol(df_sub_sorted) + 1] <- seq_len(nrow(df_sub))
  # Name the column
  colnames(df_sub_sorted)[ncol(df_sub_sorted)] <- paste0('rank_', c_name)

  for_merge <- dplyr::select(df_sub_sorted, geo_id, paste0('rank_', c_name))
  df_ranks <- sp::merge(df_ranks, for_merge, by = "geo_id")
}

df = subset(df_ranks, select = -c(geometry) )

df_ranks_noGeo <- st_drop_geometry(df_ranks)
write.csv(df, 'data/bg_stats.csv')


#add tree_area to civ
civ_loc <- read_geos_civ_assoc()
df_ranks <- read.csv('data/civ_stats.csv')
demo_civ <- read_demographics_civic_association_csv()
trees <- read_tree_data()
civ_loc$tree_count <- lengths(st_intersects(civ_loc, trees))

canopy_civ <- read_land_area_civic_association_csv()

df_ranks <- merge(df_ranks, civ_loc, by.x = "geo_id", by.y="geo_id")
df_ranks <- merge(df_ranks, canopy_civ, by.x ="geo_id", by.y="geo_id")

df_ranks$tree_area <- df_ranks$tree_count/df_ranks$area_m_sq

columns <- c('tree_area')

for (c_name in columns) {
    df_sub <- dplyr::select(df_ranks, geo_id, c_name)
    df_sub_sorted <- df_sub[order(-df_sub[,c_name]),]

    # Add column of rank in
    df_sub_sorted[, ncol(df_sub_sorted) + 1] <- seq_len(nrow(df_sub))
    # Name the column
    colnames(df_sub_sorted)[ncol(df_sub_sorted)] <- paste0('rank_', c_name)

    for_merge <- dplyr::select(df_sub_sorted, geo_id, paste0('rank_', c_name))
    df_ranks <- sp::merge(df_ranks, for_merge, by = "geo_id")
}

df = subset(df_ranks, select = -c(geometry) )

df_ranks_noGeo <- st_drop_geometry(df_ranks)
write.csv(df, 'data/civ_stats_toomany.csv')


#get corresponding civic association
#trying this again to create join csv with simplified
simplified <- read.csv('data/blockgroup_simplified.csv')
simplified <- read_excel('data/blockgroup_simplified.xlsx')
bg_all <- read_geos_block_group()
bg_all$geo_id <- as.numeric(bg_all$geo_id)
bg_all <- merge(bg_all, simplified, by.x = 'geo_id', by.y = 'geo_id')
civ_all <- read_geos_civ_assoc()
civ <- dplyr::select(civ_all, civ_name, geo_id, geometry)

b_loc_sf <- sf::st_sf(bg_all)
civ_loc <- sf::st_sf(civ)

combined <- sf::st_join(bg_all, civ, join = st_intersects)
intersect <- st_intersection(bg_all, civ)
comgined2 <- st_join(b_loc_sf, civ_loc, left=TRUE)

intersect <- st_drop_geometry(intersect)
write.csv(intersect, 'data/bg_ca_intersect.csv')
