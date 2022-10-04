Orientation of the streets of Helsinki by district
================
Tuija Sonkkila
2022-10-04

``` python
import numpy as np
import matplotlib.pyplot as plt
import osmnx as ox
```

``` python
ox.config(log_console = True, use_cache = True)
ox.__version__
```

``` r
library(dplyr)
library(sf)
streets <- readRDS("streets.RDS")

districts <- streets %>% 
  st_drop_geometry() %>% 
  distinct(kaupunginosa) 

write.csv(districts, "districts.csv", row.names = FALSE, quote = FALSE)
```

``` python
districts = {y: y + ', Helsinki, Finland' for y in [x for x in open('districts.csv').read().split('\n') if x]}
```

``` python
# Header; no streets of type 'drive' in the next two; Pasila is trapped in an HTTP error loop
# because earlier errors are all cached. How to to get rid of those?
remove_keys = ('kaupunginosa', 'Suomenlinna', 'Mustikkamaa-Korkeasaari', 'Pasila')
for key in remove_keys:
    if key in districts:
        del districts[key]
        
# https://github.com/KBergermann/Urban-multiplex-networks/blob/2d3225edb50d8a0fab641f847adc8bdbcfc1d686/subroutines/OSMnx_street_orientations.py

n = len(districts)

ncols = int(np.ceil(np.sqrt(n)))
nrows = int(np.ceil(n / ncols))

figsize = (ncols * 5, nrows * 5)
fig, axes = plt.subplots(nrows, ncols, figsize = figsize, subplot_kw = {"projection": "polar"})

for ax, district in zip(axes.flat, sorted(districts.keys())):
  print(ox.utils.ts(), district)
  
  G = ox.graph_from_place(district, network_type = "drive")
  Gu = ox.add_edge_bearings(ox.get_undirected(G))
  fig, ax = ox.bearing.plot_orientation(Gu, ax = ax, title = district, area = False, 
  title_font = {"family": "sans-serif", "fontsize": 30}, xtick_font = {"family": "sans-serif", "fontsize": 15})
    
fig.tight_layout()
fig.subplots_adjust(hspace = 0.35)

fig.savefig("districts.pdf", facecolor = "w", dpi = 100, bbox_inches = "tight")
        
plt.close()
```

``` python
# Pasila 
G = ox.graph_from_place('Pasila, Helsinki, Finland', network_type = "drive")
Gu = ox.add_edge_bearings(ox.get_undirected(G))
fig, ax = ox.bearing.plot_orientation(Gu, title = 'Pasila', area = False, title_font = {"family": "sans-serif", "fontsize": 30}, xtick_font = {"family": "sans-serif", "fontsize": 15})

fig.savefig("pasila.pdf", facecolor = "w", dpi = 100, bbox_inches = "tight")
plt.close()
```