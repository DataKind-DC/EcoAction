library(leaflet)
library(htmlwidgets)
library(ggplot2)

quick_map <- function(sf_df, file_prefix, ...) {
  #' create leaflet polygon map and save as html widget in 'maps' directory
  #'
  #' @inheritParams create_map
  #' @param file_prefix string to name file (do not include extension)
  lf <- create_map(sf_df, ...)
  file <- paste("maps/", file_prefix, ".html", sep="")
  htmlwidgets::saveWidget(lf, file = file)
  print(paste("Saved map to", file))
}

create_map <- function(sf_df, ...) {
  #' create a leaflet map with polygons
  #'
  #' @param sf_df an sf data.frame including polygons
  #' @param ... named arguments passed on to leaflet::addPolygons() for
  #' customization
  #'
  #' @returns leaflet map
  leaflet::leaflet(sf_df) %>%
    leaflet::addProviderTiles("CartoDB.Positron") %>%
    leaflet::addPolygons(
      weight = 1,
      smoothFactor = 0.5,
      opacity = 1.0,
      fillOpacity = 0.5,
      ...
    )
}

gmap <- function(sf_df, ...) {
  #' create a non-interactive map in ggplot2
  #'
  #' Creating a map in ggplot2 is faster and often works when leaflet doesn't.
  #' This is helpful in cases where you just want to look at the data. It is
  #' not appropriate for production.
  #'
  #' @param sf_df an sf data.frame
  #' @param ... named arguments passed on to ggplot2::geom_sf() for
  #' customization
  ggplot2::ggplot(data = sf_df) +
    ggplot2::geom_sf(...)
}
