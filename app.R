## 1. Packages, Data and Helper Functions
library(shiny)
library(shinyWidgets)
library(datagovsgR)
library(dplyr)
library(sf)
library(leaflet)
library(htmltools)

# Changing strings to to Title Case
frmt_str = function(x) {
  return(tools::toTitleCase(tolower(x)))
}

# HDB Carpark Information
cp_info = readr::read_csv("hdb-carpark-information.csv") %>%
  select(id = car_park_no, everything()) %>%
  mutate(address = frmt_str(address),
         car_park_type = frmt_str(car_park_type),
         short_term_parking = frmt_str(short_term_parking),
         night_parking = frmt_str(night_parking))

# Function to pull for the latest Carpark Information
pull_cp_avail = function() {
  carpark_availability() %>% 
    left_join(cp_info, by = "id") %>%
    filter(!is.na(address),
           total_lots != 0) %>%
    st_as_sf(coords = c("x_coord", "y_coord"),
             crs = 3414) %>%
    st_transform(crs = 4326) %>%
    mutate(fill_percentage = round(availability_lots / total_lots * 100,
                                   digits = 2),
           last_update = frmt_str(last_update) %>%
             sub(pattern = "t", replacement = " "))
}

# Creating a data frame to populate the basic information
df = pull_cp_avail()

# Colour palette for full percentage
pal = colorNumeric("RdYlGn", domain = df$fill_percentage)



### 2. UI

ui <- bootstrapPage(
  
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  
  leafletOutput("map", width = "100%", height = "100%"),
  
  absolutePanel(top = 40, 
                right = 30,
                
                sliderInput(inputId = "fillPercentage", 
                            label = "Availability (%)",
                            min = 0,
                            max = 100,
                            value = c(0,100),
                            step = 1),
                
                br(),
                
                pickerInput(inputId = "carpark_select",
                            label = "Search for a carpark:",
                            choices = list("Carpark" = c("Carparks", df$address)),
                            options = list(`live-search` = TRUE,
                                           `dropdown-align-right` = TRUE)),
                
                br(),
                
                checkboxInput(inputId = "legend",
                              label = "Show Legend",
                              value = FALSE),
                
                br(),
                
                actionButton(inputId = "refresh",
                             label = "Refresh"),
                style = "opacity: 0.9; background: #FFFFFF; padding: 25px",
                width = "350px"
                )
)




### 3. Server

server <- function(input, output, session) {
  
  # Pulling the latest information, as of loading the app 
  df_latest = pull_cp_avail()
  
  # Rendering base leaflet map
   output$map = renderLeaflet({
     
     leaflet(df_latest) %>%
       addProviderTiles(providers$OneMapSG.Night, 
                        options = providerTileOptions(opacity = 0.7),
                        group = "Basic Information") %>%
       addProviderTiles(providers$CartoDB.DarkMatterNoLabels,
                        options = providerTileOptions(opacity = 0.7),
                        group = "Basic Information") %>%
       setView(lat = "1.3521",
               lng = "103.8198",
               zoom = 12.5) %>%
       
       addCircles(radius = 30,
                  stroke = TRUE,
                  fillOpacity = 0.8,
                  popup = paste0("<b>Address:</b> ", df$address, "<br>",
                                 "<b>Availability: </b>", df$availability_lots,
                                 " / ", df$total_lots, "<br>"),
                  color = ~pal(fill_percentage),
                  group = "Basic Information")
   })
   
   # Zooming to selected address
   observe({
     
     if (input$carpark_select != "Carparks") {
       
       location = df_latest %>% 
         filter(address == input$carpark_select) %>% 
         st_coordinates() %>%
         c()
       location_info = df_latest %>% 
         filter(address == input$carpark_select)
       
       leafletProxy("map", data = df_latest) %>%
         flyTo(lat = location[2],
                 lng = location[1],
                 zoom = 18) %>%
         addPopups(lat = location[2],
                   lng = location[1],
                   popup = paste0("<b>Address:</b> ", location_info$address, "<br>",
                                    "<b>Availability: </b>", location_info$availability_lots,
                                    " / ", location_info$total_lots, "<br>"))
     }
   })
   
   # Reactive filtered data
   df_filtered = reactive({
     df_latest[df_latest$fill_percentage >= input$fillPercentage[1] & 
                 df_latest$fill_percentage <= input$fillPercentage[2], ]
   })
   
   # Reactive filtered availability
   observe({
     leafletProxy("map", data = df_filtered()) %>%
       clearShapes() %>%
       addCircles(radius = 30,
                  stroke = TRUE,
                  fillOpacity = 0.8,
                  popup = paste0("<b>Address:</b> ", df$address, "<br>",
                                 "<b>Availability: </b>", df$availability_lots,
                                 " / ", df$total_lots, "<br>"),
                  color = ~pal(fill_percentage),
                  group = "Basic Information")
   })
   
   
   # Adding Legend
   observe({
     
     proxy = leafletProxy("map", data = df_latest)
     proxy %>% clearControls()
     
     if (input$legend) {
       proxy %>% addLegend(position = "bottomright",
                           pal = pal,
                           values = ~fill_percentage,
                           title = "Availability",
                           labFormat = labelFormat(suffix = "%"),
                           opacity = 0.9)
     }
   })
   
   # Reloading with latest data
   observe({
     
     proxy = leafletProxy("map", data = pull_cp_avail())
     proxy %>% clearControls()
     
     if (input$refresh) {
       proxy %>% addCircles(radius = 30,
                            stroke = TRUE,
                            fillOpacity = 0.8,
                            popup = paste0("<b>Address:</b> ", df$address, "<br>",
                                           "<b>Availability: </b>", df$availability_lots,
                                           " / ", df$total_lots, "<br>"),
                            color = ~pal(fill_percentage),
                            group = "Basic Information")
       
     }
   })
}

# 4. Run the application 
shinyApp(ui = ui, server = server)

