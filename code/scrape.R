source("code/utils/setup.R")
walk(list.files("code/utils", full.names=T), source)
genres <- c("k-pop", "k-rap", "korean r&b", "k-indie", "korean pop",
            "korean trap", "korean city pop", "korean indie rock")

korean_artists <- map_dfr(genres, function(g){
  message(g)
  get_all_genre_artists(g)
})  %>% 
  filter(!duplicated(id)) %>% 
  mutate(images = map(images, ~.[1,])) %>% 
  select(-followers.href, -uri, -type, -href) %>% 
  unnest(cols = images) %>% 
  rename_at(vars(height, url, width), ~paste0("image_",.)) %>% 
  as_tibble

saveRDS(korean_artists, "data/artist_info.RDS")
korean_artists <- readRDS("data/artist_info.RDS")
artist_ids <- unique(korean_artists$id)

#Then get the entire track list for every artist, returning the artist ID if there's a failure (perhaps spotify API will reject some requests). This will take some time. It's also clunky. Whatever haha
get_artist_safely <- function(artist_id){
  artist_num <- which(artist_ids == artist_id)
  func <- possibly(get_artist_tracks, otherwise = artist_id)
  tracks <- func(artist_id) %>% mutate(main_artist = artist_id)
  if(is.numeric(tracks)) message("ERROR OCCURRED ON ARTIST ", artist_id)
  return(tracks)
}

library(tictoc)
tic()
artists_total <- map(artist_ids, get_artist_safely)
toc()

success <- artists_total[unlist(map(artists_total, ~(class(.) != "character")))]
rerun <- artists_total[unlist(map(artists_total, ~(class(.) == "character")))] %>% 
  map(get_artist_safely)

artists_total <- c(success,rerun) %>% reduce(bind_rows)
saveRDS(artists_total, "data/artists_tracks.RDS")






