library(shiny)
library(shinydashboard)
library(tidyverse)
library(leaflet)
library(sf)

source("polygonangle.R")
streets <- readRDS("streets.RDS")
areas <- as.vector(sort(c(unique(streets$kaupunginosa))))

ui <- function(request) { 
  dashboardPage(
    dashboardHeader(
      title = "Streets of Helsinki as minimum bounding boxes with angle", titleWidth = "800px"
    ),
    dashboardSidebar(disable = TRUE),
    dashboardBody(
      fluidRow(
        box(width = 6, 
            selectizeInput(inputId = "area",
                           label = "District",
                           choices = areas,
                           selected = NULL,
                           multiple = FALSE,
                           options = list(
                             placeholder = 'Select a district',
                             onInitialize = I('function() { this.setValue(""); }')
                           ))
        ),
        box(title = "About",
            width = 6,
            HTML("<a href='https://github.com/tts/hkidistricts'>R code</a> by <a href='https://twitter.com/ttso'>@ttso</a>
                  <br/>
                  Data: <a href='https://hri.fi/data/en_GB/dataset/helsingin-kaupungin-yleisten-alueiden-rekisteri'>Register of public areas in the City of Helsinki</a>.
          ")),
      ),
      fluidRow(
        box(title = "Plot", 
            height = 500,
            width = 12,
            plotOutput("plot")
            ),
        box(title = "Map",
            height = 500,
            width = 12,
            leafletOutput("map")
            ))
      )
  )}


server <- function(input, output, session) {
  
  area_chosen <- reactive({
    streets %>% 
      filter(kaupunginosa %in% input$area) %>% 
      st_geometry() %>% 
      st_as_sf() 
  })

  output$map <- renderLeaflet({
    req(input$area)
    leaflet(area_chosen()) %>%
      addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>%
      addPolygons(weight = 1,
                  color = "black")
  })

  output$plot <- renderPlot({
    req(input$area)
    pmap_dfr(area_chosen(), min_box_sf) %>%
      ggplot() +
      geom_sf(alpha = .8) +
      ggtitle(paste(input$area, collapse = " | ")) +
      labs(caption = "Data: Register of public areas in the City of Helsinki hri.fi | @ttso ") +
      theme(panel.background = element_rect(fill = "transparent", colour = NA),
            panel.grid = element_blank(),
            panel.border = element_blank(),
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            plot.margin = unit(c(0, 0, 0, 0), "null"),
            plot.background = element_rect(fill = "transparent", colour = NA),
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            axis.text = element_blank())
    })
}

shinyApp(ui = ui, server = server)
