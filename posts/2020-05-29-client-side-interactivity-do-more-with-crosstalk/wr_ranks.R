library(tidyverse)
library(rvest)
library(ggridges)

raw_url <- "https://www.pro-football-reference.com/play-index/draft-finder.cgi?request=1&year_min=2006&year_max=2020&type=&round_min=1&round_max=30&slot_min=1&slot_max=500&league_id=&team_id=&pos[]=WR&college_id=all&conference=any&show=all"
raw_url2 <- "https://www.pro-football-reference.com/play-index/draft-finder.cgi?request=1&year_min=2006&year_max=2020&type=&round_min=1&round_max=30&slot_min=1&slot_max=500&league_id=&team_id=&pos%5B%5D=WR&college_id=all&conference=any&show=all&offset=300"

te_url <- "https://www.pro-football-reference.com/play-index/draft-finder.cgi?request=1&year_min=2006&year_max=2020&type=&round_min=1&round_max=30&slot_min=1&slot_max=500&league_id=&team_id=&pos[]=TE&college_id=all&conference=any&show=all"
raw_html <- raw_url %>% 
        read_html()

raw_html_2 <- raw_url2 %>% 
        read_html()

tab_1 <- raw_html %>% 
        html_table() %>% 
        .[[1]] %>% 
        janitor::clean_names() %>% 
        as_tibble()

tab_2 <- raw_html_2 %>% 
        html_table() %>% 
        .[[1]] %>% 
        janitor::clean_names() %>% 
        as_tibble()

tab_3 <- te_url %>% 
        read_html() %>% 
        html_table() %>% 
        .[[1]] %>% 
        janitor::clean_names() %>% 
        as_tibble()

wr_tab <- tab_1 %>% 
        bind_rows(tab_2) %>%
        # bind_rows(tab_3) %>% 
        select(2:5, 8:10, 12:receiving_3)

cl_names <- wr_tab[1,] %>% as.character() %>% 
        janitor::make_clean_names()

cl_names %>% 
        datapasta::vector_paste()



cl_names <- c("year", "rnd", "pick", "player", "tm", "from", "to", "pb", "st", "car_av", 
  "g", "gs", "rush_att", "rush_yds", "rush_td", "rec", "rec_yds", "rec_td")

all_wrs <- wr_tab %>% 
        set_names(nm = cl_names) %>% 
        filter(year != "Year") %>% 
        type_convert() %>% 
        filter(!is.na(rec)) %>% 
        mutate(years = to-from + 1,
               avg_td = rec_td/years)

all_wrs %>% 
        group_by(rnd) %>%
        summarize(across(contains("rec"),
                         list(sum = ~sum(.x, na.rm = TRUE),
                              mean = ~mean(.x, na.rm = TRUE))), 
                  n = n(),
                  mean_car_av = mean(car_av, na.rm = TRUE),
                  sum_years = sum(years),
                  mean_years = mean(years))

all_wrs %>% 
        group_by(rnd) %>%
        slice_max(n = 32, order_by = rec_yds/g) %>% 
        select(rnd, player, rec, g) %>% 
        ungroup() %>% 
        mutate(td_g = rec/g) %>% 
        ggplot(aes(x = td_g, y = factor(rnd))) +
        geom_density_ridges(quantiles = 2, quantile_lines = TRUE,
                            alpha =0.5) +
        theme_ridges()
