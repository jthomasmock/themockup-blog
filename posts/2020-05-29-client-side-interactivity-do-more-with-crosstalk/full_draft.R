
scrape_draft <- function(year){
  
  url_draft <- glue::glue("https://www.pro-football-reference.com/years/{year}/draft.htm")
  
  raw_html <- read_html(url_draft)
  
  draft_names <- c("rnd", "pick", "tm", "player", "pos", "age", "end_yr",
                   "start_years", "car_av", "dr_av", "g", "rush_att", 
                   "rush_yds", "rush_td", "rec", "rec_yds", "rec_td")
  
  raw_html %>% 
    html_node("#drafts") %>% 
    html_table() %>% 
    janitor::clean_names() %>% 
    as_tibble() %>%
    select(1:7, 10:13, 19:24) %>% 
    set_names(nm = draft_names) %>% 
    mutate(draft_yr = year, .before = end_yr) %>% 
    filter(rnd != "Rnd") %>% 
    type_convert()
  
}

clean_draft %>% 
  filter(tm == "LVR")
  count(tm, sort = TRUE) %>% 
  tail()

draft_full <- 1990:2020 %>% 
  map_dfr(scrape_draft)

clean_draft <- draft_full %>% 
  group_by(draft_yr, pos) %>% 
  mutate(pos_rank = row_number(), .before = rnd) %>% 
  ungroup() %>% 
  mutate(tm = case_when(
    tm == "STL" ~ "LAR",
    tm == "RAI" ~ "LVR",
    tm == "RAM" ~ "LAR",
    tm == "PHO" ~ "ARI",
    tm == "OAK" ~ "LVR",
    tm == "SDG" ~ "LAC",
    TRUE ~ tm
  ))

# What yardage/td does a top 10 WR get?

clean_draft %>% 
  group_by(draft_yr) %>%
  filter(pos_rank <= 10 & pos == "WR") %>% 
  summarize(yds = mean(rec_yds, na.rm = TRUE)/mean(g, na.rm = TRUE), 
            td = mean(rec_td, na.rm = TRUE)/mean(g, na.rm = TRUE))

# How many drafted by round and yr
clean_draft %>% 
  group_by(draft_yr) %>%
  filter(pos_rank <= 10 & pos == "WR") %>%  
  count(rnd) %>% 
  ggplot(aes(x = rnd, y = draft_yr, fill = n)) +
  geom_tile() +
  viridis::scale_fill_viridis()

# How many total by rnd
clean_draft %>% 
  group_by(draft_yr) %>%
  filter(pos_rank <= 10 & pos == "WR") %>%  
  select(pos_rank, rnd, player, contains("rec"), g) %>% 
  ungroup() %>% 
  ggplot(aes(x = rnd)) +
  geom_histogram(binwidth = 1, color = "white")

# Distributions of stats

# rec/g
clean_draft %>% 
  group_by(draft_yr) %>%
  filter(pos_rank <= 10 & pos == "WR") %>%  
  mutate(td_g = rec_td/g,
         rec_g = rec/g,
         rec_yds_g = rec_yds/g) %>% 
  ggplot(aes(x = rec_g, y = factor(pos_rank))) +
  geom_density_ridges(quantiles = 2, quantile_lines = TRUE,
                      alpha =0.5) +
  theme_ridges()

# td/g
clean_draft %>% 
  group_by(draft_yr) %>%
  filter(pos_rank <= 10 & pos == "WR") %>%  
  mutate(td_g = rec_td/g,
         rec_g = rec/g,
         rec_yds_g = rec_yds/g) %>% 
  ggplot(aes(x = td_g, y = factor(pos_rank))) +
  geom_density_ridges(quantiles = 2, quantile_lines = TRUE,
                      alpha =0.5) +
  theme_ridges()

# yds/g
clean_draft %>% 
  group_by(draft_yr) %>%
  filter(pos_rank <= 10 & pos == "WR") %>%  
  mutate(td_g = rec_td/g,
         rec_g = rec/g,
         rec_yds_g = rec_yds/g) %>% 
  ggplot(aes(x = rec_yds_g, y = factor(pos_rank))) +
  geom_density_ridges(quantiles = 2, quantile_lines = TRUE,
                      alpha =0.5) +
  theme_ridges()


# how many WRs drafted in top 10 by each team?
clean_draft %>% 
  group_by(draft_yr) %>%
  filter(pos_rank <= 10 & pos == "WR") %>% 
  group_by(tm) %>% 
  summarize(n = n(),
            avg_pos = mean(pick)) %>% 
  arrange(desc(n)) %>% 
  # print(n = 16) %>% 
  left_join(clean_draft %>%
              filter(rnd == 1) %>% 
              group_by(tm) %>% 
              summarize(avg_pick = mean(pick, na.rm = TRUE)) %>% 
              arrange(desc(avg_pick)),
            by = "tm"
  ) %>% 
  ggplot(aes(x = avg_pick, y = avg_pos)) + geom_point()

