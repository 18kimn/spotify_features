get_artist_tracks <- function(artist_id, include_groups =  c("album", "single", "appears_on", "compilation"), authorization = get_spotify_access_token()){

  artist_albums <- get_artist_albums(artist_id, include_groups = include_groups, 
                                     include_meta_info = TRUE, authorization = authorization, limit = 50)
  num_loops_artist_albums <- ceiling(artist_albums$total/50)
  if (num_loops_artist_albums > 1) {
    artist_albums <- map_df(1:num_loops_artist_albums, function(this_loop) {
      get_artist_albums(artist_id, include_groups = include_groups, limit = 50, 
                        offset = (this_loop - 1) * 50, authorization = authorization)
    })
  } else {
    artist_albums <- artist_albums$items
  }
  artist_albums <- artist_albums %>% 
    rename(album_id = id, album_name = name) %>% 
    mutate(album_release_year = case_when(release_date_precision == "year" ~ suppressWarnings(as.numeric(release_date)),
                                          release_date_precision == "day" ~ year(as.Date(release_date, "%Y-%m-%d",
                                                                                         origin = "1970-01-01")), 
                                          TRUE ~ as.numeric(NA)))
  
  album_tracks <- map_df(artist_albums$album_id, function(this_album_id) {
    album_tracks <- get_album_tracks(this_album_id, include_meta_info = TRUE, 
                                     authorization = authorization) 
    num_loops_album_tracks <- ceiling(album_tracks$total/50)
    if (num_loops_album_tracks > 1) {
      album_tracks <- map_df(1:num_loops_album_tracks, 
                             function(this_loop) {
                               get_album_tracks(this_album_id, offset = (this_loop - 
                                                                           1) * 50,
                                                limit = 50, 
                                                authorization = authorization)
                             })
    } else {
      album_tracks <- album_tracks$items
    }
    album_tracks <- album_tracks %>% 
      filter(unlist(map(artists, function(list_item) artist_id %in% list_item$id))) %>% 
      mutate(album_id = this_album_id, 
             album_href = artist_albums$external_urls.spotify[artist_albums$album_id == this_album_id],
             album_name = artist_albums$album_name[artist_albums$album_id == this_album_id],
             album_img = artist_albums$images[artist_albums$album_id == this_album_id][[1]][1,],
             album_date = artist_albums$release_date[artist_albums$album_id == this_album_id]) %>% 
      rename(track_name = name, track_uri = uri, 
              track_preview_url = preview_url, track_href = external_urls.spotify, track_id = id) %>% 
      select(artists, track_name, track_href, track_id,  album_name, album_href, album_id, album_img, album_date)
  })
  
  return(album_tracks)
}
