library(stringr)
library(tidyverse)
library(viridis)
library(ggwordcloud)
library(treemapify)

setwd("C:/Users/mdanjach/Sciebo/home/digital-humanities/")



# sources
lines <- readLines('data/data_raw/bernstein_lexisnexis_sources_2026-03-06.txt')

n <- vector(length = length(lines))
source <- vector(length = length(lines))


for(i in seq_along(lines)){
  line <- lines[i]
  parts <- str_split(line, " ")[[1]]
  
  n[i] <- parts[length(parts)]
  source[i] <- paste(parts[1:length(parts)-1], collapse = " ")
}

df <- tibble(SOURCE = source, N = as.numeric(n))

write.csv(df, "data/data_processed/bernstein_lexisnexis_sources_2026-03-06.csv", row.names = FALSE)


df |> 
  ggplot(aes(label = SOURCE, size = N, colour = N)) +
  geom_text_wordcloud() +
  theme_minimal() +
  scale_color_viridis(direction = -1, end = 0.6)



# branches
lines <- readLines('data/data_raw/bernstein_lexisnexis_industry_2026-03-06.txt')

n <- vector(length = length(lines))
industry <- vector(length = length(lines))


for(i in seq_along(lines)){
  line <- lines[i]
  parts <- str_split(line, " ")[[1]]
  
  n[i] <- parts[length(parts)]
  industry[i] <- paste(parts[1:length(parts)-1], collapse = " ")
}

df <- tibble(INDUSTRY = industry, N = as.numeric(n))

write.csv(df, "data/data_processed/bernstein_lexisnexis_industry_2026-03-06.csv", row.names = FALSE)


df <- df |> 
  mutate(P = round(N/sum(N)*100,2)) |> 
  mutate(P = paste0('(', P, '%)')) |> 
  mutate(LABEL = paste(INDUSTRY, P, sep = "\n"))

df |> 
  ggplot(aes(area = N, fill = INDUSTRY, label = LABEL)) +
  geom_treemap() +
  scale_fill_viridis_d(direction = -1) +
  theme(legend.position = "none") +
  geom_treemap_text(colour = "white",
                    place = "centre",
                    size = log(df$N)+5)


# processing full texts Rheinische Post

library(tidyjson)
library(jsonlite)
library(tidyverse)
setwd("C:/home/digital-humanities/")

df <- fromJSON("data/data_raw/rp_leonard_berstein.json")
df <- df$Document |> tibble()

library(rvest)
library(xml2)

titles <- vector(length = 910)
published <- vector(length = 910)
texts <- vector(length = 910)

for(i in seq_along(texts)){
  html <- df$Content[i] |> read_html()
  
  marker <- html |>  
    html_node("marker")
  if(!is.na(marker)){
    xml2::xml_remove(marker)
  }
  
  titles[i] <- html |> 
    html_node("title") |> 
    html_text()
  
  published[i] <- html |> 
    html_node("published") |> 
    html_text() |> 
    substr(1, 10)
  
  texts[i] <- html |> 
    html_node("bodytext") |> 
    html_text() |> 
    trimws()
  
  print(i)
}


df <- tibble(title = titles, pubDate = published, text = texts)
df <- df |> 
  mutate(text = paste(title, text))

df <- df |> 
  mutate(across(everything(), trimws)) 
df$text <- str_replace_all(df$text, "\\s+", " ")

df <- df |> 
  distinct()

df$docID <- paste0("RP_", sprintf("%03d", c(1:nrow(df))))


library(spacyr)
library(reticulate)
spacy_initialize(model = "de_core_news_sm")

texts <- setNames(df$text, df$docID)

df_parse <- spacy_parse(texts)
df_parse <- df_parse |> tibble()

df <- df_parse |> 
  select(doc_id, token, lemma, pos) |> 
  filter(!(pos %in% c("X", "PUNCT"))) |> 
  group_by(doc_id) |> 
  reframe(
    docID = unique(doc_id),
    lemma = paste(lemma, collapse = " "),
    pos = paste(pos, collapse = " ")
    ) |> 
  ungroup() |> 
  left_join(df |> select(docID, text)) |> 
  select(docID, text, lemma, pos)

library(tm)
stops <- c(stopwords(kind = "de"), "dass")

library(tidytext)
df <- df |> 
  group_by(docID) |> 
  unnest_tokens(lemmas, lemma, to_lower = FALSE) |> 
  anti_join(tibble(lemmas = stops)) |> 
  summarise(text = paste(lemmas, collapse = " "), .groups = 'drop') 
  
system("rm -rf data/data_processed/rp_leonard_bernstein_docs/*")
for(i in 1:nrow(df)){
  
  writeLines(
    text = df$text[i], 
    con = paste0("data/data_processed/rp_leonard_bernstein_docs/", df$docID[i], "_lemmas.txt")
  )
}

df <- read_delim("data/data_processed/bernstein_rp_collocates.csv", delim = "\t")


maxWeight <- max(df$Likelihood)

word_cloud_data <- df |>
  select("word" = Collocate, "weight" = Likelihood) |> 
  add_row(word = "Bernstein", weight = maxWeight * 1.2) |> 
  arrange(desc(weight))  # Arrange by weight in descending order

ggplot(word_cloud_data, aes(label = word, size = weight, colour = weight)) +
  geom_text_wordcloud(rm_outside = TRUE, nudge_y = 0, nudge_x = 0) +  
  scale_size_area(max_size = 25) +
  theme_minimal() +
  scale_color_viridis(direction = -1, end = 0.9)





graph <- df |> 
  mutate(source = "Bernstein") |> 
  select(source, "target" = Collocate, "weight" = Likelihood) |> 
  graph_from_data_frame()

plot(graph)

