# Title     : Civic Association Report Page
# Objective : Create individual page for each CA that shows maps and stats
# Created by: a hooman (most likely)
# Created on: 4/10/21
library(dplyr)
library(sf)
library(units)

source("src/load_data.R")
source("src/leaflet_helpers.R")
source("src/sf_helpers.R")

civ_geo_df <- read_geos_civ_assoc()

civ_geo_id <- 59
civ_geo <- civ_geo_df[civ_geo_df$geo_id == civ_geo_id, "geometry"]
civ_name <- civ_geo_df[civ_geo_df$geo_id == civ_geo_id, "civ_name"]

# MAP OF OPEN PLANTABLE AREAS --------------------------------------------------
open_plantable <- readRDS("data/rds/open_plantable_mpoly.rds")
civ_open_plantable <- sf::st_intersection(open_plantable, civ_geo)

sf_df <- civ_open_plantable

leaflet::leaflet(sf_df) %>%
  leaflet::addProviderTiles("CartoDB.Positron") %>%
  leaflet::addPolygons(
    weight = 0.2,
    # smoothFactor = 0.5,
    # opacity = ,
    fillOpacity = 0.5,
  ) %>%
  leaflet::addPolygons(
    data = civ_geo,
    weight = 2,
    fillOpacity = 0.2,
    color = "gray"
  )

# DATA TABLE FOR CIV ASSOC -----------------------------------------------------
demo_df <- read_demographics_civic_association_csv()
la_df <- read_land_area_civic_association_csv()
la_df <- dplyr::select(la_df, -civ_name, -modified)

df <- sp::merge(demo_df, la_df, by = "geo_id") %>%
  dplyr::mutate(
    thousand_ppl_per_sq_mile = tot_pop_race / (area_m_sq / 2.59e6) / 1000,
    canopy_sq_ft_per_capita = (area_canopy * 10.7639) / tot_pop_race,
  )

df_ranks <- dplyr::select(df, civ_name, geo_id)

columns <- c('pct_in_poverty', 'pct_nonwhite', 'canopy_sq_ft_per_capita',
             'thousand_ppl_per_sq_mile', 'pct_canopy', 'pct_open_plantable')

for (c_name in columns) {
  df_sub <- dplyr::select(df, geo_id, c_name)
  df_sub_sorted <- df_sub[order(-df_sub[,c_name]),]

  # Add column of rank in
  df_sub_sorted[, ncol(df_sub_sorted) + 1] <- seq_len(nrow(df_sub))
  # Name the column
  colnames(df_sub_sorted)[ncol(df_sub_sorted)] <- paste0('rank_', c_name)

  df_ranks <- sp::merge(df_ranks, df_sub_sorted, by = "geo_id")
}


write.csv(df_ranks, 'data/civ_stats.csv')

civ_stats <- df_ranks[df_ranks$geo_id == civ_geo_id,]


# IDEA FOR OVERLAY OF BLOCK-GROUPS ON CIV ASSOC --------------------------------
# This looks pretty bad right now

bg_in_civs <- read_block_group_area_in_civics_csv()

bg_in_civ <- bg_in_civs[,c('geo_id','Buckingham')]
bg_in_civ <- bg_in_civ[bg_in_civ$Buckingham > 100,]

bg_geo <- read_geos_block_group()

bg_geo_subset <- bg_geo[bg_geo$geo_id %in% bg_in_civ$geo_id,]

ggplot2::ggplot(data = civ_geo) +
  ggplot2::geom_sf(fill = 'blue', alpha = 0.2) +
  ggplot2::geom_sf(data = bg_geo_subset, fill='red', alpha=0.2)



# qpal <- leaflet::colorQuantile(
#   palette = "RdPu",
#   domain = demo$pct_nonwhite, n = 7)
#
# map <- sf_df %>%
#   leaflet() %>%
#   # Base groups
#   addProviderTiles("CartoDB.Positron") %>%
#   #addProviderTiles("CartoDB.Positron", group = 'blank')%>%
#   # Overlay groups
#   addPolygons(color = qpal_can(canopy$pct_canopy),
#               weight = 1,
#               smoothFactor = 0.5,
#               opacity = 1.0,
#               fillOpacity = 0.5,
#               group = layers[1],
#               label = labels
#   ) %>%
#   addPolygons(color = qpal_openplant(canopy$pct_open_plantable),
#               weight = 1,
#               smoothFactor = 0.5,
#               opacity = 1.0,
#               fillOpacity = 0.5,
#               group = layers[2],
#               label = labels
#   ) %>%
#   # file <- paste("maps/", file_prefix, ".html", sep="")
#   # htmlwidgets::saveWidget(lf, file = file)
#   # print(paste("Saved map to", file))
#
#   # quick_map(civ_open_plantable)
#
#   # bg_on_civs_df <- read_block_group_area_in_civics_csv()
#   # blocks_on_civ_tb <- blocks_tb %>% dplyr::filter(area_on_civ > 0)
#   #


