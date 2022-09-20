library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(lwgeom) # shinyapps.io asks for this

source("polygonangle.R")

streets <- readRDS("streets.RDS")

areas <- as.vector(sort(unique(streets$kaupunginosa)))

themes <- list("Dark" = theme_dark(),
               "Minimal" = theme_minimal(),
               "Void" = theme_void())

ui <- fluidPage(
  
  sidebarPanel(
    selectizeInput(inputId = "area",
                   label = "District",
                   choices = areas,
                   selected = NULL,
                   multiple = TRUE,
                   options = list(maxItems = 4)),
    selectInput(inputId = "theme",
                label = "Theme",
                choices = names(themes),
                selected = NULL),
    HTML("<p></p>
          <span style='color:black;font-size:12px'
          <p>
            Select one or more areas, and the plot theme.
          </p>
          <p></p>
          <p>
          </p>
          <p><a href='https://github.com/tts/lakes'>R code</a> by <a href='https://twitter.com/ttso'>@ttso</a>.</p>
          <p></p>
          <p>Data: <a href='https://hri.fi/data/en_GB/dataset/seutukartta'>Helsinki Region Map</a>.</p>
          </span>"),
    width = 3
  ),

  mainPanel(
    tabsetPanel(
      tabPanel("Plot", 
               plotOutput("plot", height = 400, width = "100%")),
      tabPanel("Map", 
               leafletOutput("map", height = 400, width = "100%"))
    ),
    width = 9
  ))

  

server <- function(input, output, session) {
  
  plot_theme <- reactive({themes[[input$theme]]})
  
  area_chosen <- reactive({
    streets %>% 
      filter(kaupunginosa %in% input$area) %>% 
      st_geometry() %>% 
      st_as_sf() 
  })
  
  output$map <- renderLeaflet({
    leaflet(area_chosen()) %>% 
      addTiles() %>% 
      addPolygons(weight = 1, color = "black")
  })

  output$plot <- renderPlot({
    pmap_dfr(area_chosen(), min_box_sf) %>%
      ggplot() +
      geom_sf(alpha = .8) +
      ggtitle(paste(input$area, collapse = " | ")) +
      plot_theme() 
  })
  
  
}

shinyApp(ui, server)
