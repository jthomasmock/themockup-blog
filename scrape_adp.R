test_url <- "https://www.fantasypros.com/nfl/rankings/consensus-cheatsheets.php"


scrape_fp_draft_ranks <- function(position, scoring){
        
        message(glue::glue("Scraping {scoring} {position} ranks!"))
        
        if (scoring == "standard" & position == "overall") {
                scrape_url <- "https://www.fantasypros.com/nfl/rankings/consensus-cheatsheets.php"
        } else if (scoring == "ppr" & position == "overall") {
               scrape_url <- "https://www.fantasypros.com/nfl/rankings/ppr-cheatsheets.php"
        } else if (scoring == "half" & position == "overall") {
               scrape_url <- "https://www.fantasypros.com/nfl/rankings/half-point-ppr-cheatsheets.php"
        } else if (tolower(position) == "qb" & tolower(scoring) %in% c("standard", "half", "ppr")) {
               scrape_url <- "https://www.fantasypros.com/nfl/rankings/qb-cheatsheets.php"
        } else if (scoring == "standard" & position != "overall") {
               scrape_url <- glue::glue("https://www.fantasypros.com/nfl/rankings/{position}-cheatsheets.php")
        } else if (scoring == "ppr" & position != "overall") {
               scrape_url <- glue::glue("https://www.fantasypros.com/nfl/rankings/ppr-{position}-cheatsheets.php")
        } else if (scoring == "half" & position != "overall") {
                scrape_url <- glue::glue("https://www.fantasypros.com/nfl/rankings/half-point-ppr-{position}-cheatsheets.php")
        }  else {
                warning("Position not found!")
        }
        
        raw_html <- read_html(scrape_url) %>% 
                html_node("#rank-data")
        
        nfl_team <- raw_html %>% 
                html_nodes(".grey") %>% 
                html_text()
        
        name_full <- raw_html %>% 
                html_nodes(".full-name") %>% 
                html_text()
        
        name_short <- raw_html %>% 
                html_nodes(".short-name") %>% 
                html_text()
        
        scrape_overall <- function(){
                raw_html %>% 
                        html_table(fill = TRUE) %>% 
                        set_names(nm = names(.) %>% tolower()) %>% 
                        select(rank, player = 3, pos:avg, std_dev = `std dev`) %>% 
                        as_tibble() %>% 
                        mutate(tier = if_else(str_detect(rank, "Tier"), rank, NA_character_),
                               tier = str_remove(tier, "Tier ") %>% as.integer()) %>% 
                        fill(tier) %>% 
                        filter(str_detect(rank, "[0-9]"), !str_detect(rank, "Tier")) %>% 
                        mutate(position = str_extract(pos, "[:alpha:]+"),
                               name_full = name_full,
                               name_abb = name_short, 
                               pos_rank = str_remove(pos, position) %>% as.integer(),
                               team = if_else(position == "DST",
                                              str_sub(name_abb, 1, 3) %>% str_trim(),
                                              str_sub(player, -4) %>% str_extract("[A-Z]+"))) %>% 
                        select(rank, name_full, name_abb, team, pos = position, pos_rank, bye:std_dev) %>% 
                        mutate_at(vars(rank, bye:std_dev), as.double)
        }
        
        
        scrape_position <- function(){
                raw_html %>% 
                html_table(fill = TRUE) %>% 
                set_names(nm = names(.) %>% tolower()) %>% 
                select(rank, player = 3, bye:avg, std_dev = `std dev`) %>% 
                mutate(pos = toupper(position)) %>% 
                as_tibble() %>% 
                mutate(tier = if_else(str_detect(rank, "Tier"), rank, NA_character_),
                       tier = str_remove(tier, "Tier ") %>% as.integer()) %>% 
                fill(tier) %>% 
                filter(str_detect(rank, "[0-9]"), !str_detect(rank, "Tier")) %>% 
                mutate(position = str_extract(pos, "[:alpha:]+"),
                       name_full = name_full,
                       name_abb = name_short, 
                       pos_rank = if_else(position != "overall",
                                          as.integer(rank),
                                          str_remove(pos, position) %>% as.integer()),
                       team = if_else(position == "DST",
                                      str_sub(name_abb, 1, 3) %>% str_trim(),
                                      str_sub(player, -4) %>% str_extract("[A-Z]+"))) %>% 
                select(rank, name_full, name_abb, team, pos = position, pos_rank, bye:std_dev) %>% 
                mutate_at(vars(rank, bye:std_dev), as.double)
        }
        
        if (position == "overall" & scoring %in% c("ppr", "standard", "half")){
                scrape_overall()
        } else {
                scrape_position()
        }
}

scrape_draft_rankings("overall", "ppr")

test_html <- scrape_draft_rankings("overall", "standard") %>% 
        read_html()

test_html %>% 
        html_node("#rank-data")


test_html <- test_url %>% 
        read_html() %>% 
        html_node("#rank-data")

nfl_team <- test_html %>% 
        html_nodes(".grey") %>% 
        html_text()

name_full <- test_html %>% 
        html_nodes(".full-name") %>% 
        html_text()

name_short <- test_html %>% 
        html_nodes(".short-name") %>% 
        html_text()

test_html %>% 
        html_table(fill = TRUE) %>% 
        set_names(nm = names(.) %>% tolower()) %>% 
        mutate(tier = if_else(str_detect(rank, "Tier"), rank, NA_character_),
               position = str_extract(pos, "[:alpha:]+")) %>% 
        fill(tier) %>% 
        filter(str_detect(rank, "[0-9]"), !str_detect(rank, "Tier")) %>% 
                as_tibble() %>% 
        mutate(name_full = name_full,
               name_abb = name_short, 
               team = nfl_team,
               pos_rank = str_remove(pos, position) %>% as.integer())

test_df <- test_html %>% 
        html_table(fill = TRUE) %>% 
        set_names(nm = names(.) %>% tolower()) %>% 
        select(rank, player = 3, pos:avg, std_dev = `std dev`) %>% 
        as_tibble() %>% 
        mutate(tier = if_else(str_detect(rank, "Tier"), rank, NA_character_),
               tier = str_remove(tier, "Tier ") %>% as.integer()) %>% 
        fill(tier) %>% 
        filter(str_detect(rank, "[0-9]"), !str_detect(rank, "Tier")) %>% 
        mutate(position = str_extract(pos, "[:alpha:]+"),
               name_full = name_full,
               name_abb = name_short, 
               pos_rank = str_remove(pos, position) %>% as.integer(),
               team = if_else(position == "DST",
                              str_sub(name_abb, 1, 3) %>% str_trim(),
                              str_sub(player, -4) %>% str_extract("[A-Z]+"))) %>% 
        select(rank, name_full, name_abb, team, pos = position, pos_rank, bye:std_dev) %>% 
        mutate_at(vars(rank, bye:std_dev), as.double)

test_df %>% filter(str_detect(player, "DST"))

test_df %>% 
        filter(rank <= 100) %>% 
        ggplot(aes(x = rank, y = pos_rank, color = pos)) +
        geom_point() +
        scale_y_reverse()

pull(test_df, `overall (team)`)

nfl_team <- test_html %>% 
                html_node("#rank-data") %>% 
                html_nodes(".grey") %>% 
        html_text()

name_full <- test_html %>% 
        html_node("#rank-data") %>% 
        html_nodes(".full-name") %>% 
        html_text()

name_short <- test_html %>% 
        html_node("#rank-data") %>% 
        html_nodes(".short-name") %>% 
        html_text()




