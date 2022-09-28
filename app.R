library(shiny)
library(shinydashboard)
library(tidyverse)
library(leaflet)
library(sf)

source("polygonangle.R")
hki <- readRDS("hki.RDS")
streets <- readRDS("streets.RDS")
allstreets_range <- readRDS("allstreets_range.RDS")

areas <- as.vector(sort(c(unique(streets$kaupunginosa))))

ui <- function(request) { 
  dashboardPage(
    dashboardHeader(
      title = "Geographic orientation of the streets of Helsinki", titleWidth = "800px"
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
                  Data: <a href='https://hri.fi/data/en_GB/dataset/helsingin-kaupungin-yleisten-alueiden-rekisteri'>Register of public areas in the City of Helsinki</a>")),
      ),
      fluidRow(
        box(title = uiOutput("district_name"), 
            height = 400,
            width = 6,
            plotOutput("plot", height = "340px")),
        box(title = uiOutput("district_angle"), 
            height = 400,
            width = 6,
            plotOutput("polar", height = "340px"))
        ),
      fluidRow(
        box(title = NULL,
            height = 400,
            width = 12,
            leafletOutput("map", height = "340px")
        )),
      fluidRow(
        box(title = "Count of street angles by degree range, all districts",
            height = 400,
            width = 12,
            plotOutput("hki", height = "340px"))
      ),
      fluidRow(
        box(title = "Streets by degree range on map, all districts",
            width = 6, 
            selectInput(inputId = "level",
                        label = "Degree range",
                        choices = c("",levels(allstreets_range$Range)[1:6]),
                        selected = NULL,
                        multiple = FALSE)
        ),
      ),
      fluidRow(
        box(title = "Street angle range, all districts",
            height = 400,
            width = 12,
            leafletOutput("map2", height = "340px"))
      )
    )
  )}


server <- function(input, output, session) {
  
  area_chosen <- reactive({
    streets %>% 
      filter(kaupunginosa %in% input$area) %>% 
      st_geometry() %>% 
      st_as_sf() 
  })

  area_angle <- reactive({
    withProgress(message = "Calculating", value = 0.5, {
      pmap_dfr(area_chosen(), min_box_sf)
    })
  })
  
  map_angle_level <- reactive({
    allstreets_range %>%
      filter(Range == input$level)
  })
  
  output$district_name <- renderUI({
    req(input$area)
    paste0(input$area, " - minimum bounding boxes by angle")
  })
  
  plot_theme <- theme(panel.background = element_rect(fill = "transparent", colour = NA),
                      panel.grid = element_blank(),
                      panel.border = element_blank(),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      plot.margin = unit(c(0, 0, 0, 0), "null"),
                      plot.background = element_rect(fill = "transparent", colour = NA),
                      axis.line = element_blank(),
                      axis.ticks = element_blank(),
                      axis.text = element_blank(),
                      axis.title = element_blank())
  
  output$plot <- renderPlot({
    req(input$area)
    area_angle() %>% 
      ggplot() +
      geom_sf(alpha = .8) +
      plot_theme
  })
  
  output$district_angle <- renderUI({
    req(input$area)
    paste0(input$area, " - count of angles by range")
  })
  
  output$polar <- renderPlot({
    req(input$area)
    
    area <- area_angle()
    
    area$range <- cut(area$angle, breaks = seq(0, 180, 30))
    
    range_count <- data.frame(area$range) %>% 
      rename(range = area.range) %>% 
      dplyr::count(., range)
    
    area_range <- left_join(area, range_count) %>% 
      rename(Range = range)
    
    # https://rpubs.com/mattbagg/circular
    ggplot(area_range, aes(x = angle, fill = Range)) + 
      geom_histogram(breaks = seq(0, 360, 30), colour = "grey") + 
      coord_polar(start = 4.71, direction = -1) + 
      theme_minimal() + 
      scale_fill_brewer() + 
      ylab("Count") + 
      scale_x_continuous("", limits = c(0, 360),
                        breaks = seq(0, 360, 30),
                        labels = c(seq(0, 330, 30), ""))
    
  })
  
  output$map <- renderLeaflet({
    req(input$area)
    leaflet(area_chosen()) %>%
      addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>%
      addPolygons(weight = 1, color = "black")
  })
  
  output$map2 <- renderLeaflet({
    req(input$level)
    leaflet(map_angle_level()) %>%
      addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>%
      addPolygons(weight = 1, color = "black")
  })
  
  output$hki <- renderPlot({
    hki
  })
  
}

shinyApp(ui = ui, server = server)
