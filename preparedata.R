library(tidyverse)
library(sf)

baseurl <- "https://kartta.hel.fi/ws/geoserver/avoindata/wfs?version=1.0.0&request=GetFeature"
type <- "avoindata:YLRE_Katualue_alue"
request <- paste0(baseurl, "&typeName=", type)
str <- st_read(request, stringsAsFactors = FALSE)

streets <- str %>% 
  filter(!st_is_empty(.)) %>% 
  select(gml_id, kadun_nimi, kaupunginosa, osa_alue, suurpiiri, pituus) %>% 
  st_set_crs(3879) 

streets <- streets %>% 
  st_transform(4326)

saveRDS(streets, "streets.RDS")

source("polygonangle.R")

# Geographic orientation of all streets

streets_geo <- streets %>% 
  st_geometry() %>% 
  st_as_sf() 

allstreets <- pmap_dfr(streets_geo, min_box_sf) 

allstreets$range <- cut(allstreets$angle, breaks=seq(0,180,30))

range_count <- data.frame(allstreets$range) %>%
  rename(range = allstreets.range) %>%
  dplyr::count(., range)

allstreets_range <- left_join(allstreets, range_count) %>% 
  rename(Range = range)

hki <- ggplot(allstreets_range, aes(x = angle, fill = Range)) + 
  geom_histogram(breaks = seq(0, 180, 30), colour = "grey") + 
  coord_polar(start = 0) + 
  theme_minimal() + 
  scale_fill_brewer() + 
  ylab("Count") + 
  scale_x_continuous("", limits = c(0, 180), breaks = seq(0, 180, 30), labels = seq(0, 180, 30))

saveRDS(hki, "hki.RDS")

