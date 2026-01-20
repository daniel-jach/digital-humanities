library(rvest)
library(stringr)
library(tidyverse)


setwd("M:/fdm/dh")

files <- list.files("data_raw/beratungsprotokolle_html_2026-01-20/", full.names = TRUE)

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




df |> 
  filter(complete.cases(df)) |>
  filter(faks > 10) |> 
  count(faks) |> 
  ggplot(aes(x = faks, y = n, colour = faks)) +
  geom_bar(stat = "identity") +
  theme_minimal()


