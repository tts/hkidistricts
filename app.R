library(shiny)
library(tidyverse)
library(leaflet)
library(sf)

source("polygonangle.R")
streets <- readRDS("streets.RDS")
areas <- as.vector(sort(c(unique(streets$kaupunginosa))))

themes <- list("Dark" = theme_dark(),
               "Light" = theme_light())

ui <- fluidPage(
  
  tags$h2(
    HTML("Streets of Helsinki with angle (minimum bounding box)")
  ),
  
  sidebarPanel(
    selectizeInput(inputId = "area",
                   label = "District",
                   choices = areas,
                   selected = NULL,
                   multiple = FALSE,
                   options = list(
                     maxItems = 1,
                     placeholder = 'Pick a district',
                     onInitialize = I('function() { this.setValue(""); }')
                   )),
    selectInput(inputId = "theme",
                label = "Style",
                choices = names(themes),
                selected = "Light"),
    
    HTML("<p></p>
          <span style='color:black;font-size:12px'
          <p><a href='https://github.com/tts/hkidistricts'>R code</a> by <a href='https://twitter.com/ttso'>@ttso</a>.</p>
          <p></p>
          <p>Data: <a href='https://hri.fi/data/en_GB/dataset/helsingin-kaupungin-yleisten-alueiden-rekisteri'>Register of public areas in the City of Helsinki</a>.</p>
          </span>"),
    width = 3),

  mainPanel(
    tabsetPanel(
      tabPanel("Plot", 
               plotOutput("plot")),
      tabPanel("Map", 
               leafletOutput("map"))
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
      addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>% 
      addPolygons(weight = 1, 
                  color = "black")
  }) 

  output$plot <- renderPlot({
    req(input$area, input$theme)
    
    pmap_dfr(area_chosen(), min_box_sf) %>%
      ggplot() +
      geom_sf(alpha = .8) +
      ggtitle(paste(input$area, collapse = " | ")) +
      labs(caption = "Source: hri.fi Register of public areas in the City of Helsinki | @ttso ") +
      plot_theme() +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            axis.text = element_blank(),
            plot.title = element_text(size = 20),
            plot.caption = element_text(margin = margin(10, 0, 0, 0)))
    }, height = 600)
  
}

shinyApp(ui, server)
