# Existing pacakge state

library(tidyverse)
all_pkg <- sessioninfo::session_info("installed") |> 
  pluck("packages") |> 
  as_tibble()

split_repo <- all_pkg |> 
  mutate(repo = case_when(
    str_detect(source, "CRAN") ~ "CRAN",
    str_detect(source, "Github") ~ "GitHub",
    str_detect(source, "local") ~ "local",
    str_detect(source, "r-universe") ~ "r-universe",
    TRUE ~ NA_character_
  ), .before = "source") 

split_repo |> 
  write_csv("_data/packages.csv")

# Install R 4.2
# Install tidyverse

library(tidyverse)
all_pkg <- readr::read_csv("_data/packages.csv")

cran_pkg <- all_pkg |> 
  dplyr::filter(repo == "CRAN") |> 
  dplyr::pull(package)

cran_pkg 

inst_pkg <- sessioninfo::session_info("installed")$packages |>
  dplyr::as_tibble()

cran_pkg |>
  dplyr::select(package) |>
  filter(!(package %in% inst_pkg$package))
%>% 
  pull(package) %>% 
  install.packages()


gh_pkg <- all_pkg |> 
  filter(repo == "GitHub") |> 
  pull(package)

gh_filter <- all_pkg |> 
  filter(repo == "GitHub") |> 
  select(package, source) |> 
  separate(source, into = c("gh", "repo", "hash"), sep = " \\(|@") |> 
  filter(package %in% c("chromote", "webshot2", "gtExtras", "espnscrapeR", "datapasta",
    "crrri", "emo", "geomtextpath", "gistfo", "gtsummary", "icons", "knitr",
    "nflfastR", "nflplotR", "nflreadr", "patchwork", "quarto", "rsconnect", "tomtom",
    "sass", "rtweet", "xaringanExtra")) 

gh_filter |>
  pull(repo) |> 
  remotes::install_github(upgrade = "never")
  