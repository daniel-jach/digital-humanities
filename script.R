library(rvest)
library(stringr)
library(tidyverse)
library(viridis)


setwd("M:/digital-humanities/")

files <- list.files("data/data_raw/beratungsprotokolle_html_2026-01-20/", full.names = TRUE)

faks <- vector(length = length(files))
dates <- vector(length = length(files))
for(i in seq_along(files)){
  
  file <- files[i]
  
  html <- read_html(file)
  
  infos <- html |> 
    html_node("table") |> 
    html_text()
    
  faks[i] <- str_extract(infos, regex("Fakultät(\\d\\d)"), group = 1)
  dates[i] <- str_extract(infos, regex("(\\d\\d\\d\\d)"), group = 1)
  
  
  print(paste0(i, "/", length(files)))
  
  df <- tibble(faks = faks, dates = dates)
  
}

df <- df |> 
  filter(complete.cases(df)) |> 
  mutate(dates = as.numeric(dates)) |> 
  filter(dates < 2026) |> 
  mutate(
    faks = as.numeric(faks), 
    fakType = case_when(
      faks %in% c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10) ~ "Lower Faculties",
      faks %in% c(11) ~ "Business and Economics",
      faks %in% c(12) ~ "Education & Psychology",
      faks %in% c(13) ~ "Rehabilitation",
      faks %in% c(14) ~ "Humanities and Theology",
      faks %in% c(15) ~ "Cultural Studies",
      faks %in% c(16) ~ "Arts and Sports",
      faks %in% c(17) ~ "Social Sciences",
      TRUE ~ as.character(faks)  
    )
  ) |> 
  mutate(fakType = reorder(fakType, faks)) 
  

df |> 
  count(fakType, dates) |>
  group_by(fakType) |> 
  mutate(cumSum = cumsum(n)) |> 
  ggplot(aes(x = dates, y = cumSum, group = fakType)) +
  geom_point() +
  geom_line() +
  facet_wrap(~fakType) +
  theme_minimal()

df |> 
  mutate(faks = as.character(faks)) |> 
  count(faks, dates) |>
  group_by(dates) |> 
  ggplot(aes(x = dates, y = n, group = reorder(faks, -as.numeric(faks)), fill = reorder(faks, -as.numeric(faks)))) +
  geom_bar(stat = 'identity', color = "black") +
  scale_fill_viridis_d(direction = -1) +
  theme_minimal() +
  labs(fill = "Fakultäten", x = "Jahr")
