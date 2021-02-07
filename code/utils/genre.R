get_genre_artists <- function (genre = character(), market = NULL, limit = 20, offset = 0, 
          authorization = get_spotify_access_token()) 
{
  base_url <- "https://api.spotify.com/v1/search"
  if (!is.character(genre)) {
    stop("\"genre\" must be a string")
  }
  if (!is.null(market)) {
    if (!str_detect(market, "^[[:alpha:]]{2}$")) {
      stop("\"market\" must be an ISO 3166-1 alpha-2 country code")
    }
  }
  if ((limit < 1 | limit > 50) | !is.numeric(limit)) {
    stop("\"limit\" must be an integer between 1 and 50")
  }
  if ((offset < 0 | offset > 10000) | !is.numeric(offset)) {
    stop("\"offset\" must be an integer between 1 and 10,000")
  }
  params <- list(q = str_glue("genre:\"{genre}\"") , type = "artist", 
                 market = market, limit = limit, 
                 offset = offset, access_token = authorization)

  res <- RETRY("GET", base_url, query = params, encode = "json")
  stop_for_status(res)
  res <- fromJSON(content(res, as = "text", encoding = "UTF-8"), 
                  flatten = TRUE)$artists
  #res <- res[["artists"]]$items %>% as_tibble() %>% mutate(genre = genre)
  return(res)
}


get_all_genre_artists <- function(genre){
  
  artists <- get_genre_artists(genre, limit = 50)
  num_loops <- ceiling(artists$total/50)
  artists <- artists$items
  if (num_loops > 1) {
    artists <- map_df(1:num_loops, function(this_loop) {
      get_genre_artists(genre, limit = 50, 
                        offset = (this_loop - 1) * 50)$items
    })
  } else {
    artists <- artists$items
  }
  
  artists2 <- artists %>% filter(unlist(map(genres, ~(genre %in% .) )))
}


