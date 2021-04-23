#function for output into R markdown report

library(dplyr)
library(sf)
library(units)

source("src/load_data.R")
source("src/leaflet_helpers.R")
source("src/sf_helpers.R")

outputTemplate <- function(civ_num, df_ranks, civ_geo_df){


  civ_geo_id <- civ_num
  civ_geo <- civ_geo_df[civ_geo_df$geo_id == civ_geo_id, "geometry"]
  civ_name <- civ_geo_df[civ_geo_df$geo_id == civ_geo_id, "civ_name"]
  print(civ_name$civ_name)

  # MAP OF OPEN PLANTABLE AREAS --------------------------------------------------
  open_plantable <- readRDS("data/rds/open_plantable_mpoly.rds")
  civ_open_plantable <- sf::st_intersection(open_plantable, civ_geo)

  sf_df <- civ_open_plantable

 #s <- leaflet(sf_df) %>%
    #leaflet::addProviderTiles("CartoDB.Positron") %>%
    #leaflet::addPolygons(
      #weight = 0.2,
      # smoothFactor = 0.5,
      # opacity = ,
      #fillOpacity = 0.5,
    #) %>%
    #leaflet::addPolygons(
      #data = civ_geo,
      #weight = 2,
      #fillOpacity = 0.2,
      #color = "gray"
    #)

 #s
    b <- st_bbox(civ_geo)
 civ2_g <- get_stamenmap(bbox = c(left = b[[1]], bottom = b[[2]], right = b[[3]], top = b[[4]]), zoom = 17)

 t <- read_tree_data_subset()
 civ_trees <- sf::st_intersection(t, civ_geo)

 print(ggmap(civ2_g)+
           geom_sf(data = st_sf(civ_geo[1,]$geometry), fill=alpha("gray",0.2), inherit.aes = FALSE)+
           geom_sf(data = sf_df, fill = "lightgreen", inherit.aes = FALSE)+
           geom_sf(data = civ_trees, size = civ_trees$tree_count*5, fill = "lightgreen", inherit.aes = FALSE))


  civ_stats <- df_ranks[df_ranks$geo_id == civ_geo_id,]

  #print(civ_stats)

  col1 <- c('% In Poverty', '% Non-White', 'Canopy per person', 'Population Density', '% canopy', '% open plantable')
  col2 <- c(civ_stats$pct_in_poverty, civ_stats$pct_nonwhite, civ_stats$canopy_sq_ft_per_capita, civ_stats$thousand_ppl_per_sq_mile, civ_stats$pct_canopy, civ_stats$pct_open_plantable)
  col3 <- c('% of population', '% of population','ft^2/person','1k ppl/mi^2','% of land area', '% of land area')
  col4 <- c(civ_stats$rank_pct_in_poverty, civ_stats$rank_pct_nonwhite, civ_stats$rank_canopy_sq_ft_per_capita, civ_stats$rank_thousand_ppl_per_sq_mile, civ_stats$rank_pct_canopy, civ_stats$rank_pct_open_plantable)

  tab1 <- data.frame(col1, col2, col3, col4)
  colnames(tab1) <- c('Stat','Value','Unit','Rank (out of 63)')
  tab1[,2] <-round(tab1[,2],1)
  print(kable(tab1))

  yearAg <- aggregate(civ_trees$tree_count, by=list(Category=civ_trees$year), FUN=sum)
  colnames(yearAg) <- c('Year', 'count')
  print(kable(yearAg))

  nameAg <- aggregate(civ_trees$tree_count, by=list(Category=civ_trees$tree_name), FUN=sum)
  colnames(nameAg) <- c('Year', 'count')
  print(kable(nameAg))

  #ft <- flextable(tab1)
  #ft <- autofit(ft)
  #print(ft, preview = 'docx')
  #knit_print(ft)
  #save_as_image(x = ft, path = "myimage.png")
  #print(ft, preview = 'docx')
  #include_graphics("myimage.png")
}
