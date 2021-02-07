source("code/utils/setup.R")
library(jsonlite)
library(anytime)
#cleaning the tibble of tracks 

all_genres <- c("k-pop", "k-rap", "korean r&b", "k-indie", "korean pop",
                "korean city pop",  "korean trap","korean indie rock")
artist_info <- readRDS("data/artist_info.RDS") %>% 
  mutate(main_genre = unlist(map(genres, function(x){
    x <- head(intersect(x, all_genres), 1)
    if(!length(x)) return(NA_character_)
    x
  })),
  main_genre = case_when(main_genre == "korean pop" ~ "k-pop",
                         main_genre == "korean city pop" ~ "k-pop",
                         main_genre == "korean indie rock" ~ "k-indie",
                         main_genre == "korean trap" ~ "k-rap",
                         T ~ main_genre)) %>% 
  rename(artist_name = name) %>% 
  janitor::clean_names() %>% 
  select(-genres)


dta <- readRDS("data/artists_tracks.RDS") %>% 
  janitor::clean_names() %>% 
  filter(unlist(map(artists, ~(nrow(.) > 0 & nrow(.) < 8))) #exclude missing data (pretty sure none) and massive collabs like 119 remix or code clear 
         )%>%
  unnest(cols = artists) 

#add a "most recent album" to the artist info 
artist_info <- dta %>% group_by(track_id) %>% 
  slice(1) %>% 
  group_by(id) %>% 
  mutate(album_date = anytime(album_date),
         album_year = lubridate::year(album_date)) %>% 
  slice_max(order_by = album_date, n = 1, with_ties = F) %>% 
  select(id, album_name, album_href, album_date = album_year) %>% 
  right_join(artist_info, by = "id")



#Add a "total collabs with other artists" thing
artist_info <- map_dfr(unique(artist_info$id), function(artist_id){
  track_ids <- dta %>% filter(id == artist_id) %>% pull(track_id) %>% unique()
  collab_artists_n <- dta %>% filter(track_id %in% track_ids, id != artist_id) %>% 
    group_by(id) %>% 
    count() %>% pull(id) %>% 
    unique() %>% length()
  tibble(id = artist_id, collab_artists = collab_artists_n)
}) %>% 
  right_join(artist_info, by = "id")

#Cleaning up some variables so they're easy to read 
artist_info <- artist_info %>% 
  mutate(followers_total = formatC(followers_total, format="f", big.mark=",", digits=0)
         )



#Filter for only artists in one of the main korean genres 
dta <- dta %>% 
  group_by(track_id) %>% 
  filter(all(id %in% artist_info$id)) %>% 
  ungroup()
#This sentence generates a list of pairs for each track -- if track X has three artists A B and C, the transformed table has three rows for A to B, B to A, and B to C, all for track X. It also simplifies things (although makes things less verbose) in collapsing names and hrefs. 
dta <- dta %>% 
  select(source_label = name, source_href = href, source_id = id, track_id) %>% 
  left_join(dta, by = "track_id") %>%   filter(source_label != name) %>% 
  filter(!duplicated(select(., source_label, name, track_id))) 

# saveRDS(dta, "data/collabs.RDS") #remember that the data in this file is nonexclusive collabs, so it includes collabs with those outside of the korean genres above

dta <- dta %>% 
  group_by(source_label, name) %>% 
  mutate(pair = map2(source_label, name, function(x,y) list(sort(c(x,y)))),
         collabs = n()) %>%  #the number of collabs each pair has 
  slice(1) %>% #keep only one track per pair
  group_by(source_label) %>% 
  slice_max(order_by = collabs, n = 4, with_ties = F) %>% #for each artist, keep only collabs who are in the top 3 in frequency 
  #and ensure that no artist 
  filter(!duplicated(pair)) %>% 
  rename(target_id = id, target_label = name) %>% 
  ungroup()
  
keys <- artist_info$id %>% 
  unique() %>% 
  enframe() %>% 
  mutate(name = as.integer(name -1))
links <- dta %>% left_join(keys, by =  c("source_id" = "value")) %>% 
  rename(source_key = name) %>% 
  left_join(keys, by = c("target_id" = "value")) %>% 
  rename(target_key = name,
         source = source_id, 
         target = target_id,
         value = collabs
         ) %>% 
  as.data.frame() 

saveRDS(links, "data/links.RDS")

nodes <- artist_info %>% 
  inner_join(keys, by = c("id" = "value")) %>% 
  rename(value = id) %>% 
  unique() %>% 
  group_by(main_genre) %>% 
  mutate(popularity = popularity^2, 
         popularity = 25*popularity/max(popularity)) %>% 
  ungroup() %>% 
  mutate(group = as.numeric(as.factor(main_genre))) %>% 
  as.data.frame()

saveRDS(nodes, "data/nodes.RDS")

write_json( 
  list(nodes = nodes, links = links),
  path = "data/assembled.json"
)
# network <- forceNetwork(links, nodes,
#              colourScale = JS("d3.scaleOrdinal(d3.schemeCategory10);"),
#              #height="100%", width="100%", 
#              Source = "source_key", Target = "target_key", 
#              NodeID = "node_id",  
#              Group = "main_genre",
#              #Value = "value",
#              fontFamily = "sans", 
#              Nodesize = "popularity", charge = -60,
#              radiusCalculation =  JS("d.nodesize"),
#              linkWidth = JS(".1"), 
#              fontSize = 10, opacityNoHover = 1, opacity = 1, zoom = T) %>% 
#   onRender("function(el,x) { d3.selectAll('.node').on('mouseover', null); }") %>% 
#   onRender('function(el) { el.querySelector("svg").removeAttribute("viewBox") }')
# saveWidget(network, "network.html")
