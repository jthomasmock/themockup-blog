library(tidyverse)
library(glue)
library(rvest)

# Function to scrape the top avg cap salary by player ----
scrape_projections <- function(position, week) {
        
        if (position == "qb") {
                naming <- c("", "PASS", "PASS", 'PASS', "PASS", "PASS", "RUSH", "RUSH", "RUSH", "", "")
        } else if (position == "rb") {
                naming <-  c("", "RUSH", "RUSH", "RUSH", "REC", "REC","REC", "", "")
        } else if (position == "wr") {

                naming <- c("", "REC", "REC","REC", "RUSH", "RUSH", "RUSH", "", "")
        } else {
                naming <- c("", "REC", "REC","REC", "", "")
        }
        
        # Be nice
        Sys.sleep(1)
        
        message(glue::glue("Scraping projected stats for {position} wk: {week}!"))
        
        url <- glue::glue("https://www.fantasypros.com/nfl/projections/{position}.php?week=draft")
        
        url %>%
                read_html() %>% 
                html_table() %>% 
                .[[1]] %>% 
                filter(X1 != "") %>%
                set_names(nm = .[1,]) %>%
                .[2:length(.$Player),] %>% 
                set_names(., paste({naming}, names(.), sep = "_")) %>% 
                rename("Player" = "_Player", "FL" = "_FL", "FPTS" = "_FPTS") %>% 
                mutate(position = toupper({position}),
                       week = week) %>% 
                mutate(team = str_sub(Player, -3),
                       team = str_extract(team, "[[:upper:]]+"),
                       Player = str_remove(Player, team),
                       Player = str_trim(Player)) %>% 
                select(Player, team, position, week, everything()) %>%
                rename_all(tolower)
        }

# define inputs

position <- c("qb", "rb", "wr", "te")
week <- c("draft", as.character(1:16))

# crossing for all combos of inputs
crossing(position, week)

# scrape the data
df_output <- crossing(position = position, week = week) %>% 
        pmap_dfr(scrape_projections) %>%
        mutate_at(vars(pass_yds, rush_yds, rec_yds), str_remove, ",") %>% 
        mutate_at(vars(pass_att:rec_tds), as.numeric) %>%
        mutate_at(vars(team:position), as.factor) %>% 
        as_tibble()

df_total <- filter(df_output, week == "draft") %>% 
        select(-week)

df_weekly <- filter(df_output, week != "draft") %>% 
        mutate(week = as.integer(week)) %>% 
        arrange(week)

model_all <- df_total %>% 
        rowwise() %>% 
        mutate(tds = sum(rush_tds, pass_tds, rec_tds, na.rm = TRUE),
               opp = sum(pass_att, rush_att, rec_rec, na.rm = TRUE)) %>% 
        ungroup() %>% 
        group_by(position) %>% 
        top_n(32, fpts) %>% 
        nest() %>% 
        rowwise() %>% 
        summarize(model = lm(fpts ~ opp, data) %>% glance()) %>% 
        unpack(model) %>% 
        ungroup() %>%
        select(position, r.squared) %>% 
        mutate(r.squared = round(r.squared, 3),
               label = paste("**R^2:** ",r.squared, sep = ""))

model_all

plot_df <- df_total %>% 
        rowwise() %>% 
        mutate(tds = sum(rush_tds, pass_tds, rec_tds, na.rm = TRUE),
               opp = sum(pass_att, rush_att, rec_rec, na.rm = TRUE)) %>% 
        ungroup() %>% 
        group_by(position) %>% 
        top_n(32, fpts) %>% 
        ungroup()

label_lvl <- model_all %>% 
        arrange(desc(r.squared)) %>% 
        pull(position)

label_df <- plot_df %>% 
        group_by(position) %>% 
        summarize(y_coord = max(fpts),
                  x_coord = min(opp)) %>% 
        left_join(model_all, by = c("position"))
        

plot_all <- plot_df %>% 
        mutate(position = factor(as.character(position), levels = label_lvl)) %>% 
        group_by(position) %>% 
        mutate(max_tds = max(tds),
               max_pts = max(fpts),
               max_opp = max(opp)) %>% 
        group_by(position, player) %>% 
        mutate(td_ratio = tds/total_tds,
               fp_ratio = fpts/max_pts,
               opp_ratio = opp/max_opp) %>% 
        ungroup() %>% 
        ggplot(aes(x = opp, y = fpts)) +
        geom_point(aes(size = td_ratio, color = td_ratio)) +
        geom_smooth(method = "lm") +
        ggtext::geom_rich_text(data = label_df, aes(x = x_coord, y = y_coord, label = label),
                  hjust = 0) +
        scale_x_continuous(breaks = scales::pretty_breaks(n = 6)) +
        scale_y_continuous(breaks = scales::pretty_breaks(n = 6)) +
        scale_color_viridis_c() +
        labs(x = "\nOpportunity (Rec + Rush + Pass)",
             y = "Fantasy Points\n",
             title = "Volume is predictive of Points for Top 32 players by position",
             subtitle = "QB, RB, & TE scale strongly w/ volume, WRs not as much",
             caption = "Plot: @thomas_mock | Data: FantasyPros.com") +
        facet_wrap(~position, scales = "free") +
        theme_minimal()



plot_all

wr_only <- df_total %>%
        filter(position == "WR") %>% 
        top_n(32, fpts) %>% 
        rowwise() %>% 
        mutate(opp = sum(pass_att, rush_att, rec_rec, na.rm = TRUE),
               td = sum(rush_tds, pass_tds, rec_tds, na.rm = TRUE),
               yds_rec = rec_yds/rec_rec) %>% ungroup()

rb_only <- df_total %>%
        filter(position == "RB") %>% 
        top_n(32, fpts) %>% 
        rowwise() %>% 
        mutate(opp = sum(pass_att, rush_att, rec_rec, na.rm = TRUE),
               td = sum(rush_tds, pass_tds, rec_tds, na.rm = TRUE)) %>% ungroup()

lm(fpts ~ opp + yds_rec, wr_only) %>% glance()

lm(fpts ~ opp + td, rb_only) %>% glance()
        
%>% 
        mutate(tds = sum(rush_tds, rec_tds,na.rm = TRUE),
               opp = (rush_att + pass_att))

plot_df %>% 
        mutate(position = factor(as.character(position), levels = label_lvl)) %>% 
        group_by(position) %>% 
        mutate(max_tds = max(tds),
               max_pts = max(fpts),
               max_opp = max(opp)) %>% 
        group_by(position, player) %>% 
        mutate(td_ratio = tds/max_tds,
               fp_ratio = fpts/max_pts,
               opp_ratio = opp/max_opp) %>% 
        ungroup() %>% 
        ggplot(aes(x = opp_ratio, y = fp_ratio)) +
        geom_point(aes(size = td_ratio, color = td_ratio)) +
        geom_smooth(method = "lm") +
        facet_wrap(~position) +
        geom_abline(slope = 1, intercept = 0, size = 1, color = "grey", alpha = 0.5) +
        theme_minimal() +
        coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
        ggtext::geom_rich_text(data = label_df, aes(x = 0.0, y = 1, label = label),
                               hjust = 0) +
        scale_x_continuous(breaks = scales::pretty_breaks(n = 6)) +
        scale_y_continuous(breaks = scales::pretty_breaks(n = 6)) +
        scale_color_viridis_c() +
        labs(x = "\nOpportunity (Rec + Rush + Pass, normalized by position)",
             y = "Fantasy Points (Normalized by position)\n",
             title = "Volume is predictive of Points for Top 32 players by position",
             subtitle = "QB, RB, & TE scale strongly w/ volume, WRs not as much",
             caption = "Plot: @thomas_mock | Data: FantasyPros.com")

df_total %>% 
        rowwise() %>% 
        mutate(tds = sum(rush_tds, pass_tds, rec_tds, na.rm = TRUE),
               opp = sum(pass_att, rush_att, rec_rec, na.rm = TRUE)) %>% 
        ungroup() %>% 
        group_by(position) %>% 
        top_n(32, fpts) %>% 
        group_by(position) %>% 
        mutate(max_tds = max(tds),
               max_pts = max(fpts),
               max_opp = max(opp)) %>% 
        group_by(position, player) %>% 
        mutate(td_ratio = tds/max_tds,
               fp_ratio = fpts/max_pts,
               opp_ratio = opp/max_opp) %>% 
        ungroup() %>% 
        group_by(position) %>% 
        select(player, team, position, fpts, tds, opp, contains("ratio"), contains("max")) %>% 
        nest() %>% 
        rowwise() %>% 
        summarize(model = lm(fp_ratio ~ opp_ratio, data) %>% glance(),
                  model2 = lm(fpts ~ opp, data) %>% glance()) %>% 
        unpack(model2) %>% 
        ungroup() %>%
        select(position, r.squared) %>% 
        mutate(r.squared = round(r.squared, 3),
               label = paste("**R^2:** ",r.squared, sep = ""))
