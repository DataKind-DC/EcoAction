---
title: "Arlington Trees"
author: "Rich Carder"
date: "March 31, 2020"
---

  #install.packages("lwgeom")
#install.packages("dplyr")
#remotes::install_github("r-lib/tidyselect")
#install.packages("googlesheets4")
#install.packages("formattable")
#install.packages("htmltools")
  #install.packages("geojsonio")
 # install.packages("vctrs")
library(dplyr)           # only used for nice format of Head() function here
library(gridExtra)
library(forcats) 
library(grid)
library(DescTools)
library(devtools)
library(reshape)
library(stringr)
library(tidyr)
library(timeDate)
library(lubridate)
library(RJSONIO)
library(maps)
library(rlang)
library(mapdata)
library(geosphere)
library(ggmap)
library(ggplot2)
library(tools)
library(mapplots)
library(viridis)
library(ggrepel)
library(extrafont)
library(directlabels)
library(tidyverse)
library(tidyselect)
library(googlesheets4)
library(formattable)
library(kableExtra)
library(ggthemes)
library(knitr)
library(tidycensus)
library(htmltools)
library(webshot)
library(sf)
library(haven)
library(jsonlite)
library(geojsonio)
library(lwgeom)
#This script extracts ACS 5-year estimates at the block group (or any larger 
#geography) using the tidycensus package. To run tidycensus, you first need
#to set up a Census API key and run census_api_key(). Set working directory
#to where you want output files to save, or use the collect_acs_data function 
#to set a different outpath.
#

setwd("C:/Users/rcarder/downloads")##We should change this to read directly from google drive
canopy <- st_read("Tree_Canopy_2016_Polygons-shp") 
buildings <- st_read("Building_Polygons-shp") 
setwd("C:/Users/rcarder/Documents/dev/EcoAction")


census_api_key('b2e47f1f1e9c7115a34a02992c149628712ecff8', install=TRUE, overwrite = TRUE)

#if (!require("pacman")) install.packages("pacman")
#pacman::p_load(tidyverse, tidycensus, viridis,stringr,dplyr,knitr,DT,datasets)

#For code to run, need to first set up Census API key and run census_api_key()

acs_table <- load_variables(2018, "acs5", cache = TRUE)


language <- get_acs(geography = 'block group',
                    variables = c('B16001_001','B16001_002','B16001_003','B16001_004','B16001_005',
                                  'B16001_075','B16001_006'),
                    year = 2018, state = 'Virginia',county="Arlington County", geometry = FALSE) %>%
  dplyr::select(-moe) %>%
  spread(key = 'variable', value = 'estimate') %>% 
  mutate(
    tot_population_language=B16001_001,
    only_english_pct = B16001_002/tot_population_language,
    any_other_than_english_pct = 1-(B16001_002/tot_population_language),
    spanish_pct=B16001_003/tot_population_language,
    french_pct=B16001_006/tot_population_language,
    chinese_pct=B16001_075/tot_population_language,
    spanish_with_english_pct=B16001_004/tot_population_language,
    spanish_no_english_pct=B16001_005/tot_population_language) %>%
  dplyr::select(-c(NAME))


age <- get_acs(geography = 'block group',
               variables = c(sapply(seq(1,49,1), function(v) return(paste("B01001_",str_pad(v,3,pad ="0"),sep="")))),
               year = 2015, state = "Virginia",county = "Arlington County", geometry = FALSE)%>%
  dplyr::select(-moe) %>%
  spread(key = 'variable', value = 'estimate') %>% 
  mutate(
    denom = B01001_001,
    age_under30_ma = dplyr::select(., B01001_007:B01001_011) %>% rowSums(na.rm = TRUE),
    # age_25_64_ma = dplyr::select(., B01001_011:B01001_019) %>% rowSums(na.rm = TRUE),
    age_over65_ma = dplyr::select(., B01001_020:B01001_025) %>% rowSums(na.rm = TRUE),
    age_under30_fe = dplyr::select(., B01001_031:B01001_035) %>% rowSums(na.rm = TRUE),
    #age_25_64_fe = dplyr::select(., B01001_035:B01001_043) %>% rowSums(na.rm = TRUE),
    age_over65_fe = dplyr::select(., B01001_044:B01001_049) %>% rowSums(na.rm = TRUE),
    age_pct_under30 = (age_under30_ma + age_under30_fe)/denom,
    #age_pct_25_64 = (age_25_64_ma + age_25_64_fe)/denom,
    age_pct_over65 = (age_over65_ma + age_over65_fe)/denom
  ) %>%
  dplyr::select(-starts_with("B0"))%>%dplyr::select(-ends_with("_ma")) %>% dplyr::select(-ends_with("_fe")) %>% dplyr::select(-denom)


ACS <- get_acs(geography = 'block group',
                variables = c(sapply(seq(1,10,1), function(v) return(paste("B02001_",str_pad(v,3,pad ="0"),sep=""))),
                              'B03002_001','B03002_002','B03002_003','B03002_012','B03002_013','B02017_001',
                              'B19301_001', 'B17021_001', 'B17021_002',"B02001_005","B02001_004","B02001_006"),
               year = 2018, state = "Virginia",county = "Arlington County", geometry = TRUE)%>%
  dplyr::select(-moe) %>%
  spread(key = 'variable', value = 'estimate') %>% 
  mutate(
    tot_population_race = B02001_001,
    pop_nonwhite=B02001_001-B02001_002,
    pop_nonwhitenh=B03002_001-B03002_003,
    race_pct_white = B02001_002/B02001_001,
    race_pct_whitenh = B03002_003/B03002_001,
    race_pct_nonwhite = 1 - race_pct_white,
    race_pct_nonwhitenh = 1 - race_pct_whitenh,
    race_pct_black = B02001_003/B02001_001,
    race_pct_aapi = (B02001_005+B02001_006)/B02001_001,
    race_pct_native = B02001_004/B02001_001,
    race_pct_hisp = B03002_012/B03002_001) %>%
  mutate(
    tot_population_income = B17021_001,
    in_poverty = B17021_002) %>%
  mutate(
    inc_pct_poverty = in_poverty/tot_population_income,
    inc_percapita_income = B19301_001) %>%
  left_join(language, by="GEOID")%>%
  left_join(age, by="GEOID")%>%
  dplyr::select(-starts_with("B0"))%>%
  dplyr::select(-starts_with("B1"))


FullData<-ACS

FullData$area <- st_area(FullData$geometry)


##plots to test
nonwhite<-ggplot() +
  geom_sf(data = FullData, aes(fill=(race_pct_nonwhitenh)),color=NA,alpha=1) +
  scale_fill_gradient(low="white",high="#ffbb00",na.value="white",limits=c(min(FullData$race_pct_nonwhitenh, na.rm = TRUE), max(FullData$race_pct_nonwhitenh, na.rm = TRUE)),labels=scales::percent_format(accuracy=1))+
  geom_sf(data = FullData, color = '#ffbb00', fill = NA, lwd=.1)+
  labs(fill="% Non-White")+
  map_theme()+
  theme(legend.position = "right")+
  geom_sf(data = canopy,fill="green",color=NA,alpha=.4)



canopymap<-ggplot() +
  geom_sf(data = canopy,fill="green",color=NA,alpha=.4) 


##Make coordinate systems the same and compatible with Mapbox
st_crs(canopy)
st_crs(FullData)
st_crs(buildings)
canopy<-st_transform(canopy, crs=3857,proj4string="+proj=longlat +datum=WGS84 +no_defs")
FullData<-st_transform(FullData, crs=3857,proj4string="+proj=longlat +datum=WGS84 +no_defs")
buildings<-st_transform(buildings, crs=3857,proj4string="+proj=longlat +datum=WGS84 +no_defs")

canopynew<-st_transform(structure(canopy, proj4string = "+init=epsg:4326"), "+init=epsg:4269")
FullDatanew<-st_transform(structure(FullData, proj4string = "+init=epsg:4326"), "+init=epsg:4269")


st_crs(canopynew)
st_crs(FullDatanew)

#run the intersect function, converting the output to a tibble in the process
int <- as_tibble(st_intersection(st_make_valid(canopy), st_make_valid(FullData)))
intbuildings <- as_tibble(st_intersection(st_make_valid(buildings), st_make_valid(FullData)))


#add in an area count column to the tibble (area of each arable poly in intersect layer)
int$area <- st_area(int$geometry)
intbuildings$area <- st_area(intbuildings$geometry)

#group data by county area and calculate the total arable land area per county
#output as new tibble
newareas <- int %>%
  group_by(GEOID) %>%
  summarise(areaCanopy = sum(area))

buildingareas <- intbuildings %>%
  group_by(GEOID) %>%
  summarise(areaBuildings = sum(area))

#change data type of areaArable field to numeric (from 'S3: units' with m^2 suffix)
newareas$areaCanopy <- as.numeric(newareas$areaCanopy)
buildingareas$areaBuildings <- as.numeric(buildingareas$areaBuildings)
FullData$area <- as.numeric(FullData$area)

FullDataArea<-FullData%>%
  left_join(newareas, by="GEOID")%>%
  left_join(buildingareas, by="GEOID")%>%
  mutate(PercentCanopy=areaCanopy/area,
         NoBuilding=area-areaBuildings,
         PercentOpen=(area-areaCanopy-areaBuildings)/area)

FullDataArea$PercentCanopy <- as.numeric(FullDataArea$PercentCanopy)


setwd("C:/Users/rcarder/Documents/dev/EcoAction/data")
write.csv(ACS,"ArlingtonDemographics.csv",row.names = FALSE)

##Don't write to GitHub dir...too big
topojson_write(FullDataArea,file="TreeData.json")
shp_out <- st_write(canopy, "NewCanopy.shp")
topojson_write(buildings,file="buildings.json")





