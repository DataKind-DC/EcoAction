# EcoAction
DataKindDC project with EcoAction Arlington, through their
[Tree Canopy Fund](https://www.ecoactionarlington.org/community-programs/trees/). The goal is to determine which
neighborhoods to focus on when advertising that EcoAction can provide and plant
trees for free. The intent is to find areas that have low tree-canopy and are
lower-income.

The majority of the documentation and all of the data is stored in Google Drive.
Please reach out to [DataKindDC](https://www.datakind.org/chapters/datakind-dc)
to join the project! 


## Getting Started
After getting access to the google drive folder, clone this repo to your local environment. Then do the following:

1. Run `scripts/prep_initial_data.R` with R
    - **NOTE:** Requires the `googledrive` package and API authentication (will ask for password on first run)
    - This downloads ***EcoAction Arlington/Data/Trees_Planted/tree_data_consolidated - trees.csv*** to the `data` directory and unpacks the zip files in `data/shape_files`
1. Set `EcoAction` as the working directory in whatever IDE you are using.

_Manual approach (without R)_
1. Unzip the zip files in `data/shape_files/`
    - **NOTE:** Windows users should ensure the destination is `data/shape_files` (or nested directories will be created)
1. Download ***EcoAction Arlington/Data/Trees_Planted/tree_data_consolidated - trees.csv***
from Google Drive and place it in `EcoAction/data/` on your local.
1. Set `EcoAction` as the working directory in whatever IDE you are using.


## Repo Structure
### archive/
Contains all old scripts and code that are no longer in active development.

### data/
Relevant demographic, land area, shape files, and rds files for the project. See
`data/description_of_data.md` for more information about the csv files.

### data/shape_files/
After unzipping these files, you will see a collection of folders that contain shape files. All of these were downloaded from [Arlington County Open Data](https://gisdata-arlgis.opendata.arcgis.com/search).

### data/rds/
Folder to store rds files if needed.

### scripts/
Scripts that are intended to be run a single time to generate data files or maps.

### src/
Source files and helper functions

## Contributing
Take a look at the issues tab in this repo and select one or more to work on. 
When writing code, please do your best to write quality, readable code by following
the [tidyverse style guide](https://style.tidyverse.org/).

We highly recommend that you use pull-requests when commiting new code. 
Pull-requests require that another team member looks at your code, and are almost always
learning experiences for both parties. If you are new to github, pull-requests can 
be somewhat daunting, but it is a learning experience that we hope you won't regret!
Here is more information from github:

* [About pull requests](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests)
* [Creating a pull request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request)





