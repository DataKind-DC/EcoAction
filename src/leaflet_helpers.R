library(leaflet)
library(htmlwidgets)

quick_map <- function(sf_df, file_prefix) {
  # TODO: docstring
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

