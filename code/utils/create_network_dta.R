#From a data.frame created by get_artist_tracks(), format it into a tibble 
create_network_dta <- function(dta, input_artist){
  x <- get_artist_tracks(artist_id)
  dta <- x
  dta <- dta %>% 
    filter(unlist(map(artists, ~(nrow(.) > 1 & nrow(.) < 8))) )%>%
    unnest(cols = c(artists)) 
  
  #This sentence generates a list of pairs for each track -- if track X has three artists A B and C, the transformed table has three rows for A to B, B to A, and B to C, all for track X. It also simplifies things (although makes things less verbose) in collapsing names and hrefs. 
  dta <- dta %>% 
    select(source = name, source_href = href, track_id) %>% 
    left_join(dta, by = "track_id") %>% 
    mutate(source_href = ifelse(source == input_artist, album_href, source_href),
           target_href = ifelse(name == input_artist, album_href, source_href),
           pair = map2(source, name, function(x,y) list(sort(c(x,y))))) %>% 
    filter(source != name, !duplicated(pair)) %>% 
    mutate(across(c(source, name), function(x) case_when(x == input_artist ~ album_name, T ~ x))) %>% 
    rename(target  =name, artist_href = href, artist_id = id) %>% 
    select(-pair, -uri, -type)
  
  album_nodes <- dta %>% select()

  #Then we add new nodes form the album to the main artist. 
}

#Make each album a node, then have artists appear once "under" the first album they come from. The main artist has direct connections only to albums and nothing else. 

make_network <- function(dta){
  keys <- c(dta$source, dta$target) %>% 
    unique() %>% 
    enframe() %>% 
    mutate(name = as.integer(name -1))
  links <- dta %>% left_join(keys, by =  c("source" = "value")) %>% 
    rename(source_id = name) %>% 
    left_join(keys, by = c("target" = "value")) %>% 
    rename(target_id = name) %>% 
    mutate(value = 1) %>% 
    as.data.frame
  nodes <- keys %>% 
    left_join(dta, by = c("value" = "target")) %>% 
    left_join(dta, by = c("value" = "source")) %>% 
    mutate(id = 1:n()) %>% 
    group_by(name) %>% top_n(1, wt=  id) %>% 
    mutate(group = case_when(!is.na(group.x) ~ group.x, 
                             T ~ group.y),
           size = .4) %>% 
    as.data.frame()
  forceNetwork(links, nodes, arrows = T,
               colourScale = JS("d3.scaleOrdinal(d3.schemeCategory10);"),
               #height="100%", width="100%", 
               Source = "source_id", Target = "target_id", 
               NodeID = "value", Group = "group", Value = "value",
               fontFamily = "sans", 
               Nodesize = "size", radiusCalculation = JS("3"), 
               fontSize = 10, opacityNoHover = 1, opacity = 1, zoom = T) %>% 
    onRender("function(el,x) { d3.selectAll('.node').on('mouseover', null); }") %>% 
    onRender('function(el) { el.querySelector("svg").removeAttribute("viewBox") }')
}
