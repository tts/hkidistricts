makeplot <- function(data) {
  p <- ggplot(data, aes(x = angle, fill = factor(n))) + 
    geom_histogram(breaks = seq(0, 360, 30), colour = "grey") + 
    geom_histogram(aes(x = South, fill = factor(n)), breaks = seq(0, 360, 30), colour = "grey") + 
    coord_polar(start = 4.71, direction = -1) + # 0/360 in East as radii, counterclockwise
    theme_minimal() + 
    theme(axis.text.y = element_blank(), 
          axis.ticks = element_blank(),
          axis.title = element_blank()) +
    scale_fill_brewer() + 
    guides(fill = guide_legend("Count")) +
    scale_x_continuous("", limits = c(0, 360),
                       breaks = seq(0, 360, 30),
                       labels = c(seq(0, 330, 30), ""))
  return(p)
}
  
makemap <- function(data) {
  m <- leaflet(data) %>%
    addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>%
    addPolygons(weight = 1, color = "black") 
  return(m)
}
  