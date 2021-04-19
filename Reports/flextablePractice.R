library('flextable')

civ_geo_id <- 5

setwd('C:/Users/cle9a/Documents/Trees/GitHub_02-07-2021/EcoAction')
df_ranks <- read.csv('data/civ_stats.csv')

civ_stats <- df_ranks[df_ranks$geo_id == civ_geo_id,]

flextable(civ_stats)

col1 <- c('% In Poverty', '% Non-White', 'Canopy per person', 'Population Density', '% canopy', '% open plantable')
col2 <- c(civ_stats$pct_in_poverty, civ_stats$pct_nonwhite, civ_stats$canopy_sq_ft_per_capita, civ_stats$thousand_ppl_per_sq_mile, civ_stats$pct_canopy, civ_stats$pct_open_plantable)
col3 <- c('% of population', '% of population','ft^2/person','1k ppl/mi^2','% of land area', '% of land area')
col4 <- c(civ_stats$rank_pct_in_poverty, civ_stats$rank_pct_nonwhite, civ_stats$rank_canopy_sq_ft_per_capita, civ_stats$rank_thousand_ppl_per_sq_mile, civ_stats$rank_pct_canopy, civ_stats$rank_pct_open_plantable)

tab1 <- data.frame(col1, col2, col3, col4)
colnames(tab1) <- c('Stat','Value','Unit','Rank (out of 63)')
tab1.round(1)
tab1[,2] <-round(tab1[,2],1)

ft <- flextable(tab1)
ft <- autofit(ft)
ft
