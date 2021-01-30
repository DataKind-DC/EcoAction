library(googledrive)

# Download Trees Planted Data ----------------------------------------------

googledrive::drive_download(
    "https://drive.google.com/file/d/1YyjgOCZ_BTyAW42LevRR97LfXFwJluX9/view?usp=sharing",
    path = file.path("data", "tree_data_consolidated - trees.csv")
)


# Unzip shape file archives ------------------------------------------------

message("Unzipping shape_files...")

sf_dir <- "data/shape_files"
sf_zips <- list.files(sf_dir, pattern = "zip$", full.names = TRUE)

purrr::walk(
    sf_zips,
    ~ unzip(.x, exdir = sf_dir, overwrite = FALSE)
)

message("Done")
