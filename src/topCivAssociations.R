# Title     : topCivAssociation.R
# Objective : make map of top (or bottom) k civic association
#             two map types- binary and colored by index value
#             indices of interest
# Created by: Charlotte
# Created on: 10 April 2021

#get libraries
library(sp)
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

#extract civic associations that meet critieria
get_civ_indices <- function(civ_ind, k, top, index, filename){
    #either get top k civic association (ex- % below poverty) or bottom k
    #civic association (ex- canopy cover)
  if(top){
    civ_indices <- civ_ind[order(-civ_ind$index),]
    top <- civ_indices$geo_id[1:k]
    civ_indices<- civ_ind[match(top, civ_ind$geo_id),]
    c2 <- data.frame(civ_indices$abv, civ_indices$geo_id, civ_indices$index)
    print(c2)
    write.csv(c2, paste(filename, '.csv', sep=""))
    return(civ_indices)
  }else{
    civ_indices <- civ_ind[order(civ_ind$index),]
    top <- civ_indices$geo_id[1:k]
    civ_indices<- civ_ind[match(top, civ_ind$geo_id),]
    c2 <- data.frame(civ_indices$abv, civ_indices$geo_id, civ_indices$index)
    print(c2)
    write.csv(c2, paste(filename, '.csv', sep=""))
    return(civ_indices)
  }
}

#display value for all civic association
topK_colored <- function(civ, k, top, index, filename ){

  civ_ind <- civ[c("abv","geo_id", "geometry",index)]
  colnames(civ_ind)<-c("abv","geo_id","geometry","index")

  civ_indices <- get_civ_indices(civ_ind, k, top, index, filename)

  qpal <- leaflet::colorQuantile(
    palette = "RdPu",
    domain = civ_ind$index, n=7)

  labels <- sprintf(
    "<strong>%s</strong>", #<br/>(%g)",
    civ_indices$abv#, civ_indices$index
  ) %>% lapply(htmltools::HTML)

  map <- civ_ind$geometry %>% leaflet() %>%
    # Base groups
    addProviderTiles("CartoDB.Positron",options = providerTileOptions(minZoom = 12, maxZoom = 12.7)) %>%
    addPolygons(data = civ_ind$geometry,
                weight = 1,
                color = qpal(civ_ind$index)) %>%
    addPolygons(data = civ_indices$geometry,
                color = qpal(civ_indices$index),
                label = labels,
                weight = 5,
                fillOpacity = .8,
                labelOptions = labelOptions(noHide = T,textOnly = TRUE,
                                            style = list("font-size" = "15px"))
    )
  map
  htmlwidgets::saveWidget(map, file = paste(filename, '.html', sep=""), selfcontained=TRUE)


}

#show top (or bottom) k civic association
topK_binary <- function(civ, k, top, index, filename ){

  civ_ind <- civ[c("abv","geo_id", "geometry",index)]
  colnames(civ_ind)<-c("abv","geo_id","geometry","index")

  civ_indices <- get_civ_indices(civ_ind, k, top, index, filename)

  labels <- sprintf(
      "<strong>%s</strong>", #<br/>(%g)",
      civ_indices$abv#, civ_indices$index
  ) %>% lapply(htmltools::HTML)

  map <- civ_ind$geometry %>% leaflet() %>%
    # Base groups
    addProviderTiles("CartoDB.Positron",options = providerTileOptions(minZoom = 12, maxZoom = 12.7)) %>% #fitBounds = st_bbox(civ_ind) #minZoom = 10, maxZoom = 10
    addPolygons(data = civ_ind$geometry,
                weight = 1,
                fill = 0) %>%
    addPolygons(data = civ_indices$geometry,
                label = labels,
                weight = 1,
                labelOptions = labelOptions(noHide = T,textOnly = TRUE,
                                            style = list("font-size" = "15px"))
    )
  map
  htmlwidgets::saveWidget(map, file = paste(filename, '.html', sep=""), selfcontained=TRUE)


}



