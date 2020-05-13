scrape_fp_projections <- function(position, week) {
        
        if (position == "qb") {
                
                naming <- c("player", "pass_att", "pass_comp", 'pass_yds', "pass_tds", "pass_int", "rush_att", "rush_yds", "rush_tds", "fum_lost", "fpts")
                
        } else if (position == "rb") {
                
                naming <-  c("player", "rush_att", "rush_yds", "rush_tds", "rec", "rec_yds","rec_tds", "fum_lost", "fpts")
                
        } else if (position == "wr") {
                
                naming <- c("player", "rec", "rec_yds","rec_tds", "rush_att", "rush_yds", "rush_tds", "fum_lost", "fpts")
                
        } else {
                naming <- c("player", "rec", "rec_yds","rec_tds", "fum_lost", "fpts")
        }
        
        message(glue::glue("Scraping projected stats for {position} wk: {week}!"))
        
        url <- glue::glue("https://www.fantasypros.com/nfl/projections/{position}.php?week=draft")
        
        url %>%
                read_html() %>% 
                html_node("#data") %>% 
                html_table() %>% 
                slice(3:n()) %>% 
                set_names(nm = naming) %>% 
                mutate(pos = toupper(position),
                       week = week) %>% 
                mutate(team = str_sub(player, -3),
                       team = str_extract(team, "[[:upper:]]+"),
                       player = str_remove(player, team),
                       player = str_trim(player)) %>% 
                select(player, team, pos, week, everything()) %>% 
                mutate_at(.vars = vars(contains("yds")), str_remove, ",") %>% 
                mutate_at(.vars = vars(5:last_col()), as.double) %>% 
                as_tibble()
}

all_proj <- crossing(position = c("qb", "rb", "wr", "te"), week = "draft") %>% 
        pmap_dfr(scrape_projections)

test_df <- all_proj %>% 
        left_join(scrape_draft_rankings("overall", "half"), by = c("team", "pos", "player" = "name_full"))

test_df <- .Last.value


