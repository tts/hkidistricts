Orientation of the streets of Helsinki by district
================
Tuija Sonkkila
2022-10-04

# Installing Python libraries

I had some difficulties with the `reticulate::py_install` function.
Although the libraries seemed to have been installed just fine, `import`
failed. So I used `conda_install` instead and even defined
`use_condaenv` although it is perhaps not necessary.

``` python
import numpy as np
import matplotlib.pyplot as plt
import osmnx as ox
```

The `ox.config` is soon history so this needs to be changed at some
point.

Caching proved to be a two-edged sword in my case. It saves time
tremendously but if there is an HTTP error, you can fall into an endless
loop because the error message is cached too, and you cannot get rid of
it. When you rerun the code, the problematic item in the dictionary is
encountered at some point, the cached message fetched, and - for unknown
reasons - you’ll get the same HTTP error, it is cached etc. First I
thought the problematic item was too big to handle but when run
individually, there are no problems.

``` python
ox.config(log_console = True, use_cache = True)
ox.__version__
```

I’m not sure if Python is able to read R dataframes directly. Anyway,
made a CSV sidestep.

``` r
library(dplyr)
library(sf)
streets <- readRDS("streets.RDS")

districts <- streets %>% 
  st_drop_geometry() %>% 
  distinct(kaupunginosa) 

write.csv(districts, "districts.csv", row.names = FALSE, quote = FALSE)
```

In this list comprehension, I tried to define *skip the first row* but
didn’t succeed so I’ll delete the header from the dictionary later on.

``` python
districts = {y: y + ', Helsinki, Finland' for y in [x for x in open('districts.csv').read().split('\n') if x]}
```

By trial and error I realized that two districts do not have any streets
with the type `drive` so I needed to delete their keys. The code breaks
otherwise. Proper error handling would be the answer here.

The core functionality of the plotting code below is from the subroutine
[OSMnx_street_orientations.py](https://github.com/KBergermann/Urban-multiplex-networks/blob/2d3225edb50d8a0fab641f847adc8bdbcfc1d686/subroutines/OSMnx_street_orientations.py)
included in the `Urban-multiplex-networks`repository by [Kai
Bergermann](https://github.com/KBergermann).

As it is now and the way I understand it, before the actual plotting,
the code first allocates full columns and rows based on the number of
plots. However, plots do not fill all slots in the last row, leaving few
skeletons, empty placeholders. I need to dig further into this to find
out how to do this in a cleaner fashion.

``` python
remove_keys = ('kaupunginosa', 'Suomenlinna', 'Mustikkamaa-Korkeasaari', 'Pasila')

for key in remove_keys:
    if key in districts:
        del districts[key]

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

And then just Pasila.

``` python
G = ox.graph_from_place('Pasila, Helsinki, Finland', network_type = "drive")
Gu = ox.add_edge_bearings(ox.get_undirected(G))
fig, ax = ox.bearing.plot_orientation(Gu, title = 'Pasila', area = False, title_font = {"family": "sans-serif", "fontsize": 30}, xtick_font = {"family": "sans-serif", "fontsize": 15})

fig.savefig("pasila.pdf", facecolor = "w", dpi = 100, bbox_inches = "tight")
plt.close()
```
