library(tidyverse)
library(spotifyr)
library(lubridate)
library(networkD3)
library(htmlwidgets)
Sys.setenv(SPOTIFY_CLIENT_ID = 'fe755ce094f949e9946016ffb23af318')
Sys.setenv(SPOTIFY_CLIENT_SECRET = '79503189e72b49bcb88d5acc5fdd4b7a')

access_token <- get_spotify_access_token()

input_artist <- "pH-1"
artist_dta <-search_spotify(input_artist, type = "artist")
artist_id <- artist_dta$id[1]



get_all_tracks <- function(artist_id, input_artist){
    all_tracks <- tibble() 
  i <- 0
  message(artist_id)

  while(TRUE){
    temp_tracks <- search_spotify(paste0("", input_artist), type = "track", limit = 50, offset = 50*i)
    filtered_tracks <- temp_tracks %>% 
      filter(unlist(map(artists, function(list_item) artist_id %in% list_item$id)))
    all_tracks <- bind_rows(all_tracks, filtered_tracks)
    i <- i+1
    message(nrow(temp_tracks))
    if(nrow(temp_tracks) != 50 | nrow(filtered_tracks) == 0) break
  }
  return(all_tracks)
}


artist_tracks <- get_all_tracks(artist_id, input_artist)
artist_collabs <- map(artist_tracks$artists, ~.$id) %>% 
  unlist() %>% 
  subset(. != artist_id)
