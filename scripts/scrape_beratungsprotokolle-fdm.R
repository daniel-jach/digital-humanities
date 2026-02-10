library(rvest)
library(stringr)
library(tidyverse)
library(viridis)


setwd("C:/Users/mdanjach/Sciebo/home/digital-humanities/")

files <- list.files("data/data_raw/beratungsprotokolle-fdm_html_2026-01-20/", full.names = TRUE)

faks <- vector(length = length(files))
dates <- vector(length = length(files))
names <- vector(length = length(files))
records <- vector(length = length(files))
record_num <- rep(NA,length(files))

for(i in seq_along(files)){
  
  file <- files[i]
  
  html <- read_html(file)
  
  infos <- html |> 
    html_node("table")
  
  if(is.na(infos)){
    next
  }
  
  rows <- infos |> 
    html_nodes("tr")
  
  dates[i] <- rows[1] |> html_node("td") |> html_text() |> str_extract(regex("\\d\\d\\d\\d"))
  names[i] <- rows[2] |> html_node("td") |> html_text()
  faks[i] <- rows[4] |> html_node("td") |> html_text() |> str_extract(regex("\\d\\d"))
  records[i] <- file
  record_num[i] <- i
  
  
  print(paste0(i, "/", length(files)))

}

df <- tibble(faks = faks, dates = dates, names = names, records = records, record_num = record_num)

df <- df |> 
  mutate(
    across(1:4, ~ na_if(., "FALSE")))

write.csv(df, "data/data_processed/beratungsprotokolle-fdm.csv")
df <- read_csv("data/data_processed/beratungsprotokolle-fdm_korrigiert.csv")

df <- df |> 
  filter(!is.na(records)) |> 
  mutate(faks = case_when(
    is.na(faks) ~ "Andere",
    TRUE ~ as.character(faks))
  )

df <- df |> 
  mutate(faks = case_when(
    names == "Brandt" ~ "Andere",
    TRUE ~ as.character(faks)
  ))

saveRDS(df, "data/data_processed/beratungsprotokolle-fdm.Rda")



df <- readRDS("data/data_processed/beratungsprotokolle-fdm.Rda") |> tibble()


df |> 
  filter(names == "Watzlawik")


