library(htmltools)

url_rodgers <- "https://twitter.com/SportsCenter/status/1255168243863609344"

url <- "https://www.pro-football-reference.com/players/W/WilsRu00/touchdowns/passing/"


build_url <- glue::glue("https://www.pro-football-reference.com/players/{str_sub(name, 1)}/WilsRu00/touchdowns/passing/")


pass_table <- read_html("https://www.pro-football-reference.com/play-index/ptd_finder.cgi?request=1&match=career&year_min=2000&year_max=2019&game_type=R&game_num_min=0&game_num_max=99&week_num_min=0&week_num_max=99&td_type=pass&group_by_pass=qb&quarter%5B%5D=1&quarter%5B%5D=2&quarter%5B%5D=3&quarter%5B%5D=4&quarter%5B%5D=5&order_by=game_date") %>% 
  html_node("#all_results")

top_names <- pass_table %>% 
  html_nodes("#results > tbody > tr > td:nth-child(2)") %>% 
  html_attr("csk") %>% 
  .[c(1:9,11,12,14)]

all_names <- pass_table %>% 
  html_nodes("#results > tbody > tr > td:nth-child(2)") %>% 
  html_attr("csk")

all_urls <- pass_table %>% 
  html_nodes("#results > tbody > tr > td:nth-child(8) > a") %>% 
  html_attr("href")

top_urls <- pass_table %>% 
  html_nodes("#results > tbody > tr > td:nth-child(8) > a") %>% 
  html_attr("href") %>% 
  .[c(1:9,11,12,14)]

scrape_tds <- function(full_url){
  
  raw_html <- full_url %>% 
    read_html()
  
  passer_name <- raw_html %>% 
    html_node("#meta > div:nth-child(2) > h1") %>% 
    html_text(
      
    )
  raw_table <- raw_html %>% 
    html_node("#scores") %>% 
    html_table() %>% 
    select(Rk,Year,Tm, `Scorer/Receiver`) %>% 
    janitor::clean_names() %>% 
    filter(rk != "Rk") %>% 
    type_convert() %>% 
    as_tibble() %>% 
    mutate(passer = passer_name, .before = rk)
  
  raw_table
}

top_qbs <- tibble(
  name = top_names,
  base_url = top_urls
) %>% 
  mutate(full_url = paste0("https://www.pro-football-reference.com", base_url),
         name = str_replace(name, ","," "),
         name = paste(word(name, 2), word(name, 1)))

top_qb_tds <- top_qbs %>% 
  mutate(data = map(full_url, scrape_tds))

clean_top_tds <- top_qb_tds %>% 
  select(data) %>% 
  unnest(data) %>% 
  mutate(scorer_receiver = str_remove(scorer_receiver, "\\*"))

skill_draft <- clean_draft %>% 
  filter(pos %in% c("WR", "RB", "TE", "LB")) %>% 
  filter(end_yr >= 2001) %>% 
  mutate(player = str_remove(player, " HOF"),
         player = str_remove(player, "\\*")) %>% 
  select(pos_rank:start_years, td = rec_td)

joined_tds <- clean_top_tds %>% 
  mutate(passer = str_trim(passer)) %>% 
  group_by(passer, tm, scorer_receiver) %>% 
  count() %>% ungroup() %>% 
  left_join(skill_draft, by = c("scorer_receiver" = "player")) %>% 
  mutate(rnd = case_when(
    is.na(rnd) ~ "UDFA",
    rnd == 8 ~ "7",
    rnd == 12 ~ "UDFA",
    TRUE ~ as.character(rnd)),
    rnd = factor(rnd, levels = c(1:7, "UDFA"),
                 labels = c(sprintf("Rnd %s", 1:7), "UDFA"))) %>%
  group_by(passer) %>% 
  arrange(desc(n)) %>% 
  select(passer, tm = tm.x, scorer_receiver, n, pos_rank, rnd) %>% 
  mutate(pos_rank = if_else(rnd == "UDFA", 44, as.double(pos_rank)))

joined_tds %>% 
  write_rds("joined_tds.rds")

summary_qbs <- joined_tds %>%
  group_by(passer, rnd) %>% 
  summarize(n = sum(n)) %>% 
  group_by(passer) %>% 
  mutate(total = sum(n, na.rm = TRUE),
         ratio = n/total) %>% 
  group_by(passer) %>% 
  complete(rnd) %>% 
  ungroup() %>% 
  mutate(ratio = if_else(is.na(ratio), 0, ratio))

qb_levels <- summary_qbs %>% 
  filter(rnd == "1") %>% 
  arrange(desc(ratio)) %>% 
  pull(passer)

summary_qbs %>% 
  mutate(passer = factor(passer, qb_levels)) %>% 
  ggplot(aes(x = rnd, y = passer, fill = ratio)) +
  geom_tile() +
  viridis::scale_fill_viridis()

summary_qbs %>% 
  ggplot(aes(y = fct_rev(rnd), x = ratio)) +
  geom_col() +
  facet_wrap(~passer, ncol = 4)

joined_tds %>% 
  filter(is.na(pos)) %>% 
  group_by(scorer_receiver, tm.x) %>% count(sort = TRUE) 

summary_qbs %>% 
  write_rds("summary_qbs.rds")

GnYlRd <- function(x) rgb(colorRamp(c(viridis_pal(begin = 0.5, end = 1)(10) %>% rev()))(x), maxColorValue = 255)

qb_min <- min(summary_qbs$ratio)
qb_max <- summary_qbs %>% 
  filter(rnd %in% c("Rnd 1", "Rnd 2", "Rnd 3")) %>% 
  group_by(passer) %>% 
  summarize(sum = sum(ratio)) %>% 
  summarize(max = max(sum) + 0.01) %>% 
  pull(max)

wide_qbs <- summary_qbs %>% 
  select(passer, rnd, ratio) %>% 
  mutate(ratio = round(ratio, digits = 3)) %>% 
  pivot_wider(id_cols = passer, names_from = rnd, values_from = ratio) %>% 
  group_by(passer) %>% 
  mutate(`Rnds 1-3` = `Rnd 1`+ `Rnd 2` + `Rnd 3`, .before = UDFA) %>% 
  ungroup()

wide_qbs %>% write_rds("nfl_draft/wide_qb.rds")
  
table_out <- wide_qbs %>% 
  select(-(`Rnd 4`:`Rnd 7`)) %>% 
  reactable(
    pagination = FALSE,
    searchable = TRUE,
    defaultColDef = colDef(
      style = function(value) {
        if (!is.numeric(value)) return()
        normalized <- value/0.756
        color <- GnYlRd(normalized)
        list(background = color, fontWeight = "bold")
      },
      format = colFormat(percent = TRUE, digits = 1),
      minWidth = 125
    ),
    fullWidth = FALSE,
    columns = list(
      passer = colDef(
      minWidth = 150
    )
  )
  )

table_out

clean_top_tds %>% 
  left_join(skill_draft, by = c("scorer_receiver" = "player")) %>% 
  filter(is.na(pos)) %>% 
  group_by(scorer_receiver, tm.x) %>% count(sort = TRUE) %>% print(n = "all")


"https://www.pro-football-reference.com/players/B/BreeDr00/touchdowns/passing/" %>% scrape_tds()
  read_html() %>% 
  html_node("#scores") %>% 
  html_table()

"#all_scores"

div(
  h2("Percent of Touchdowns thrown to players by draft round"),
  h3("Normalized to each passer's total passing touchdown"),
  table_out
)
