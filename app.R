library(shiny)
library(shinyjs)
library(shinydashboard)
library(tidyverse)
library(leaflet)
library(sf)

source("polygonangle.R")
hki <- readRDS("hki.RDS")
streets <- readRDS("streets.RDS")
allstreets_range <- readRDS("allstreets_range.RDS") 

areas <- as.vector(sort(c(unique(streets$kaupunginosa))))
flevels <- levels(allstreets_range$Range)[1:6]

ui <- function(request) { 
  
  # tags$head(
  #    tags$style(HTML("
  #      div.box[div#hideme] { # no support yet for this type of selector
  #        border-top: none;
  #      }"))
  #    )

  dashboardPage(
    dashboardHeader(
      title = "Geographic orientation of the streets of Helsinki", titleWidth = "800px"
    ),
    dashboardSidebar(
      useShinyjs(),
      sidebarMenu(
        menuItem("Districts", tabName = "districts"),
        menuItem("Helsinki", tabName = "helsinki")
      ), collapsed = TRUE
    ),
    dashboardBody(
      tabItems(
        tabItem(
          tabName = "districts",
          fluidRow(
            box(width = 6, 
                selectizeInput(inputId = "area",
                               label = "Select district",
                               choices = areas,
                               selected = NULL,
                               multiple = FALSE,
                               options = list(
                                 placeholder = 'Pick one from the list',
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
            box(id = "hideme"),
            box(width = 6,
                selectInput(inputId = "deg",
                            label = "Select degree range",
                            choices = NULL)
            )
          ),
          fluidRow(
            box(title = NULL,
                height = 400,
                width = 6,
                leafletOutput("map", height = "340px")),
            box(title = NULL,
                height = 400,
                width = 6,
                leafletOutput("mapo", height = "340px"))
          )
        ),
        tabItem(
          tabName = "helsinki",
          fluidRow(
            box(title = "Count of streets by range of degree, all districts",
                height = 400,
                width = 12,
                plotOutput("hki", height = "340px"))
          ),
          fluidRow(
            box(title = NULL,
                width = 6, 
                selectInput(inputId = "level",
                            label = "Select range",
                            choices = flevels,
                            selected = flevels[1],
                            multiple = FALSE))
          ),
          fluidRow(
            box(title = "Streets mapped by range of degree, all districts",
                height = 400,
                width = 12,
                leafletOutput("map2", height = "340px"))
          )
        )
        )
      )
      
  )}


server <- function(input, output, session) {
  
  shinyjs::hide(id = "hideme")
  
  area_chosen <- reactive({
    req(input$area)
    streets %>% 
      filter(kaupunginosa %in% input$area) %>% 
      st_geometry() %>% 
      st_as_sf() 
  }) %>% 
    bindCache(input$area)

  area_angle <- reactive({
    req(input$area)

    withProgress(message = "Calculating", value = 0.5, {
      pmap_dfr(area_chosen(), min_box_sf) %>% 
        mutate(range = cut(angle, breaks = seq(0, 360, 30)))
      }) 
    }) %>% 
    bindCache(input$area, area_chosen())
  
  observe({
    req(area_angle())
    x <- sort(unique(area_angle()$range[!is.na(area_angle()$range)]))

    updateSelectInput(session, "deg",
                      choices = x,
                      selected = x[1]
    )
  })

  mapo_angle_level <- reactive({
    area_angle() %>%
      filter(range == input$deg)
  }) %>% 
    bindCache(input$deg, area_angle())
  
  map_angle_level <- reactive({
    allstreets_range %>%
      filter(Range == input$level)
  }) %>% 
    bindCache(input$level)

  output$district_name <- renderUI({
    req(input$area)
    paste0(input$area, " - minimum bounding boxes")
  }) %>% 
    bindCache(input$area)
  
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
    
    }) %>% 
      bindCache(input$area, area_angle())
  
  output$district_angle <- renderUI({
    req(input$area)
    paste0(input$area, " - count of streets by the range of degree")
  }) %>% 
    bindCache(input$area)
  
  output$polar <- renderPlot({
    req(input$area)
    
    area <- area_angle()
    
    range_count <- data.frame(area$range) %>% 
      rename(range = area.range) %>% 
      dplyr::count(., range)
    
    area_range <- left_join(area, range_count) %>% 
      rename(Range = range) %>% 
      mutate(South = angle + 180)
    
    # https://rpubs.com/mattbagg/circular
    ggplot(area_range, aes(x = angle, fill = factor(n))) + 
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
    
  }) %>% 
    bindCache(input$area, area_angle())
  
  output$map <- renderLeaflet({
    req(input$area)
    leaflet(area_chosen()) %>%
      addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>%
      addPolygons(weight = 1, color = "black") 
  }) %>% 
    bindCache(input$area, area_chosen())
  
  output$mapo <- renderLeaflet({
    req(input$deg)
    leaflet(mapo_angle_level()) %>%
      addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>%
      addPolygons(weight = 1, color = "black") 
  }) %>% 
    bindCache(input$deg, mapo_angle_level())
  
  output$map2 <- renderLeaflet({
    req(input$level)
    leaflet(map_angle_level()) %>%
      addTiles(attribution = "OpenStreetMap | Register of public areas in the City of Helsinki") %>%
      addPolygons(weight = 1, color = "black")
  }) %>% 
    bindCache(input$level, map_angle_level())
  
  output$hki <- renderPlot({
    hki
  })
  
}

shinyApp(ui = ui, server = server)
