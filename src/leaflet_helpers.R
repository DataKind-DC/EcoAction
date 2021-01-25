library(leaflet)
library(htmlwidgets)

quick_map <- function(sf_df, file_name) {
  # TODO: docstring
  lf <- leaflet::leaflet(sf_df) %>%
    leaflet::addProviderTiles("CartoDB.Positron") %>%
    leaflet::addPolygons(
      weight = 1,
      smoothFactor = 0.5,
      opacity = 1.0,
      fillOpacity = 0.5
    )

  htmlwidgets::saveWidget(lf, file = file_name)
  print(paste("Saved map to", file_name))
}

