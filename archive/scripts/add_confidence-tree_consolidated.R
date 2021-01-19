# Add color marker to original cleaned dataset for review by EcoAction Arlington
# J. Allen Baron
# 2020-12-16

library(here)
library(tidyverse)
library(readxl)
library(openxlsx)


gc_tidy <- read_csv(
    here("Data/Mapping", "geocoded_tidy.csv"),
    col_types = cols(
        needs_review = col_character(),
        .default = col_guess()
    )
) %>%
    mutate(
        confidence = case_when(
            needs_review == "x" ~ "needs_review",
            offset <= 25 ~ "high",
            offset <= 100 ~ "medium",
            offset > 100 ~ "low",
            TRUE ~ "unclear"
        )
    ) %>%
    select(address, confidence) %>%
    unique()


clean_df <- read_xlsx(
    here("Data/Tree Planting/needs_review", "tree_data_consolidated.xlsx"),
    sheet = "trees",
    col_types = c("guess", "guess", "guess", "guess", "guess", "guess",
                  "guess", "guess", "text", "text",
                  "text", "numeric")
)


combined_df <- left_join(clean_df, gc_tidy, by = "address")


write.xlsx(
    combined_df,
    here(
        "Data/Tree Planting/needs_review",
        "tree_data_consolidated_wConfidence.xlsx"
    )
)
