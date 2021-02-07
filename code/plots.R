source("code/utils/setup.R")

#summary trends of who does the most songs with other people and who works with the most number of people
highlights <- readRDS("data/collabs.RDS") %>% 
  group_by(source, source_id) %>% 
  summarize(partners = length(unique(name)), 
            tracks = length(unique(track_id))) %>% 
  left_join(artist_info, by = c("source_id" = "id")) %>% 
  ungroup()

top_genres <- c("k-pop", "k-rap", "korean r&b", "k-indie")
artist_info <- readRDS("data/artist_info.RDS") %>% 
  mutate(main_genre = unlist(map(genres, function(x){
    x <- head(intersect(x, top_genres), 1)
    if(!length(x)) return(NA_character_)
    x
  }))) %>% select(id, main_genre)


#most songs with other people
most_partners <- highlights %>% 
  top_n(15, partners) %>% 
  mutate(source = source %>% 
           str_wrap(10) %>% 
           as_factor() %>% 
           fct_reorder(partners,  .desc = T)) %>% 
  ggplot() + 
  geom_bar(aes(x = source, y = partners), fill = "#1375B7", stat = "identity") + 
  labs(y = "Number of partners throughout career", 
       x = NULL, title = "K-hiphop dominates the Korean music scene in terms of collaborations", 
       caption = "Data from the Spotify Web API, scraped through the spotifyr package in R.\nExcludes massive collabs like 119 Remix or Code Clear.",
       subtitle = "Top 15 artists by number of partners throughout career.") + 
  coord_cartesian(ylim = c(100, NaN)) + 
  theme_ipsum_rc(base_family = "Lato") + 
  theme(axis.title.y = element_text(hjust=  .5), 
        axis.text.x.bottom = element_text(size = rel(.7), margin = margin(t = 0, unit = "pt")))
ggsave("graphics/most_partners.png", plot = most_partners, height = 6, width = 10)

#most tracks with other people 
most_songs <- highlights %>% 
  top_n(15, tracks) %>% 
  mutate(source = source %>% 
           str_wrap(10) %>% 
           as_factor() %>% 
           fct_reorder(tracks, .desc = T)) %>% 
  ggplot() + 
  geom_bar(aes(x = source, y = tracks), fill = "#1375B7", stat = "identity") + 
  labs(y = "Number of tracks with other artists", 
       x = NULL, title = "K-hiphop dominates the Korean music scene in terms of collaborations", 
       caption = "Data from the Spotify Web API, scraped through the spotifyr package in R.\nExcludes massive collabs like 119 Remix or Code Clear.",
       subtitle = "Top 15 artists by number of tracks with other artists.") + 
  coord_cartesian(ylim = c(100, NaN)) + 
  theme_ipsum_rc(base_family = "Lato") + 
  theme(axis.title.y = element_text(hjust=  .5), 
        axis.text.x.bottom = element_text(size = rel(.7), margin = margin(t = 0, unit = "pt")))
ggsave("graphics/most_songs.png", plot = most_songs, height = 6, width = 10)

