library(readr)
library(dplyr)
library(tidyr)
data_path <- 'Tree Planting/'

df <- read_csv(paste(data_path, '../../data/Data/Tree Planting/tree_data_consolidated - trees.csv', sep=''), col_types =
             cols(
               row = col_double(),
               year = col_double(),
               address = col_character(),
               zipcode = col_double(),
               tree_name = col_character(),
               group_name = col_character(),
               cross_street = col_character(),
               planting_location = col_character(),
               app_type = col_character(),
               needs_review = col_character(),
               season = col_character(),
               tree_num = col_double()
             ))
summary(df)

################### EXAMINE COLUMNS ############################################
sort(unique(df$tree_name)) # Before cleanup there are 195 tree names

################### TREE NAME CLEANUP ##########################################
tree_name_cleanup <- read_csv(paste(data_path,'tree_name_cleanup - trees.csv', sep=''))

# This will add the columns from tree_name_cleanup, matching on tree_name
df_clean <- merge(df, tree_name_cleanup, by='tree_name', all.x=TRUE)
# Select and sort after cleaning tree_name and adding scientific_name and tree count
df_clean <- df_clean %>%
  select(address, zipcode, tree_count, tree_name_new, scientific_name, year, 
         group_name, cross_street, planting_location, app_type, season, 
         tree_num, needs_review) %>%
  rename(tree_name = tree_name_new)

sort(unique(df_clean$tree_name)) # After cleanup there are 59 tree names


################### FINAL SORT AND SAVE TO CSV #################################
df_clean = df_clean[order(df_clean$address),]
write.csv(df_clean, paste(data_path,'tree_data_clean.csv', sep=''), row.names=FALSE)

