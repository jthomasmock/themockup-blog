library(tidyverse)
library(lubridate)
library(here)

tues_df <- read_rds(here::here("2019", "2019-01-01", "tidytuesday_tweets.rds"))

plot_tues_df <- tues_df %>% 
        mutate(ymd_date = lubridate::date(created_at)) %>% 
        group_by(ymd_date) %>% 
        summarize(n = n()) %>% 
        ungroup() %>%
        mutate(day_of_week = lubridate::wday(ymd_date, label = TRUE),
               day_of_month = lubridate::mday(ymd_date),
               month = lubridate::month(ymd_date, label = TRUE))

(tidy_tuesday_plot <- plot_tues_df %>% 
                ggplot(aes(x = day_of_month, y = n)) +
                geom_col(aes(fill = ifelse(day_of_week == "Tue", "blue1", "grey")), color = "grey4") +
                facet_wrap(~month, ncol = 3) +
                #scale_fill_manual(values = c("blue1", "grey")) +
                scale_fill_identity() +
                guides(fill = F) +
                labs(x = "\nDay of Month (Tuesdays Highlighted)",
                     y = "Number of Tweets\n",
                     title = "Frequency of #TidyTuesday tweets over time",
                     subtitle = "Daily number of Twitter statuses using the #TidyTuesday hashtag",
                     caption = "\nData: @kearneymw/rtweet | Plot: @thomas_mock") +
                ggthemes::theme_fivethirtyeight() +
                theme(axis.title = element_text(face = "bold")) +
                NULL)


ggsave(here::here("2019", "2019-01-01", "tidy_tues_plot.png"), tidy_tuesday_plot, height = 8, width = 12, units = "in", dpi = 600)
