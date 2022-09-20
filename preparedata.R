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
