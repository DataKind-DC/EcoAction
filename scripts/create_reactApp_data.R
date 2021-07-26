library(plyr)
source("src/load_data.R")
source("src/map_year_utils.R")

bg_df <- read_geos_block_group()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~ Create open-plantable geojson for each block-group ~~~~~~~~~~~~~~~~~~~~
# WARNING: This takes forever to run
# Use this code to generate a separate file for each open_plantable area intersection with a block group
open_plantable <- readRDS("data/rds/open_plantable_mpoly.rds")
for (i in 1:nrow(bg_df)) {
  geo_id <- bg_df[["geo_id"]][i]
  geo <- bg_df[["geometry"]][i]
  geo_open_plantable <- sf::st_intersection(open_plantable, geo)
  file_name <- paste('/Users/brent/code/EcoAction/reactApp/api/data/op_', geo_id, '.geojson', sep = '')
  st_write(geo_open_plantable, dsn = file_name, driver = 'geojson')
  print(i)
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~ Create block-group names ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
df_bg_names <- tibble(geo_id = bg_df[["geo_id"]])
for (r in 1:nrow(bg_df)) {
  bbox <- st_bbox(bg_df[r, "geometry"])
  lng_mid = mean(bbox['xmin'], bbox['xmax'])
  lat_mid = mean(bbox['ymin'], bbox['ymax'])
  df_bg_names[r, 'lat_middle'] <- round(lat_mid * 2, digits = 2) / 2
  df_bg_names[r, 'lng_middle'] <- round(lng_mid, digits = 3)
  df_bg_names[r, 'sum_center'] = (abs(lng_mid) + lat_mid)
}

df_bg_names <- df_bg_names[order(-df_bg_names$lat_middle, df_bg_names$lng_middle),]
df_bg_names['bg_name'] <- 1:nrow(bg_df)
final <- dplyr::select(df_bg_names, c(bg_name, geo_id))
write.csv(final, "reactApp/api/data/block_group_names.csv", row.names = FALSE)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~ Create tree locations ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
td <- read_tree_data() %>%
  dplyr::select(td, c(row, tree_count, lat, long, geometry, address_clean))
td_final <- td
for (i in 1:nrow(bg_df)) {
  geo_id <- bg_df[["geo_id"]][i]
  geo <- bg_df[["geometry"]][i]
  t <- sf::st_intersection(td, geo)
  td_final[t[["row"]], 'block_group_id'] <- geo_id
}

reducing_logic <- function(rows) {
  if (typeof(rows[1]) == "character") {
    reduced = rows[1]
  } else {
    reduced = sum(rows)
  }
  reduced
}

td_reduced_address <- ddply(
  td_final,
  .(lat, long),
  colwise(reducing_logic, .(address_clean, block_group_id, tree_count))
)

td_reduced_address %>%
  dplyr::select(c(block_group_id, lat, long, tree_count, address_clean)) %>%
  write.csv("reactApp/api/data/trees.csv", row.names = FALSE)