library(leaflet)
library(htmlwidgets)

quick_map <- function(sf_df, file_prefix) {
  #' create leaflet polygon map and save as html widget in 'maps' directory
  #'
  #' @param sf_df an sf data.frame
  #' @param file_prefix string to name file (do not include extension)
  lf <- leaflet::leaflet(sf_df) %>%
    leaflet::addProviderTiles("CartoDB.Positron") %>%
    leaflet::addPolygons(
      weight = 1,
      smoothFactor = 0.5,
      opacity = 1.0,
      fillOpacity = 0.5
    )
  file <- paste("maps/", file_prefix, ".html", sep="")
  htmlwidgets::saveWidget(lf, file = file)
  print(paste("Saved map to", file))
}

