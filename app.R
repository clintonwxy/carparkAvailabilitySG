## 1. Packages, Data and Helper Functions
library(shiny)
library(shinyWidgets)
library(datagovsgR)
library(dplyr)
library(sf)
library(leaflet)
library(htmltools)
library(waiter)

# Changing strings to to Title Case
frmt_str = function(x) {
  return(tools::toTitleCase(tolower(x)))
}

# HDB Carpark Information
cp_info = readr::read_csv("../data/hdb-carpark-information.csv") %>%
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

# Loading screen gif
gif_load = paste0("https://i.kym-cdn.com/photos/images/original/000/516/373/3be.gif")
loading_screen_bg = tagList(h1("Give Patrick a moment", style = "color:white;"),
                            img(src = gif_load, height = "350px"))

gif_reload = paste0("https://media.giphy.com/media/TPl5N4Ci49ZQY/giphy.gif")
reloading_screen_bg = tagList(h1("Give Patrick a moment", style = "color:white;"),
                              img(src = gif_reload, height = "350px"))


### 2. UI

ui <- bootstrapPage(
  
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  
  leafletOutput("map", width = "100%", height = "100%"),
  
  absolutePanel(top = 10, 
                right = 10,
                
                h3("Carpark Availability"),
                
                br(),
                
                radioButtons(inputId = "fullDataOption",
                             label = "Information",
                             choices = c("Basic", "Full")),
                
                br(),
                
                sliderInput(inputId = "fillPercentage", 
                            label = "Filter by availability (%)",
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
                
                style = "opacity: 0.8; background: #FFFFFF; padding: 20px",
                width = "300px"
  ),
  
  use_waiter()
)

### 3. Server

server <- function(input, output, session) {
  
  loading_screen <- Waiter$new(html = loading_screen_bg,
                               color = "#192841")
  loading_screen$show()
  
  # Pulling the latest information, as of loading the app
  df_latest <<- pull_cp_avail()
  
  # Rendering base leaflet map
  output$map = renderLeaflet({
    
    leaflet(df_latest) %>%
      addProviderTiles(providers$OneMapSG.Grey, 
                       options = providerTileOptions(opacity = 0.8)) %>%
      
      setView(lat = "1.3521",
              lng = "103.8198",
              zoom = 12.5)
  })
  
  loading_screen$hide()
  
  # Reactive filtered data
  df_filtered = reactive({
    df_latest[df_latest$fill_percentage >= input$fillPercentage[1] & 
                df_latest$fill_percentage <= input$fillPercentage[2], ]
  })
  
  # Options between basic and full information
  observe({
    
    if (input$fullDataOption == "Basic") {
      
      leafletProxy("map", data = df_filtered()) %>%
        clearShapes() %>%
        addCircles(radius = 30,
                   stroke = TRUE,
                   fillOpacity = 0.8,
                   popup = paste0("<b>Address:</b> ", df_filtered()$address, "<br>",
                                  "<b>Availability: </b>", df_filtered()$availability_lots,
                                  " / ", df$total_lots, "<br>"),
                   color = ~pal(fill_percentage))
      
    } else {
      
      leafletProxy("map", data = df_filtered()) %>%
        clearShapes() %>%
        addCircles(radius = 30,
                   stroke = TRUE,
                   fillOpacity = 0.8,
                   popup = paste0("<b>Address:</b> ", df_filtered()$address, "<br>",
                                  "<b>Availability: </b>", df_filtered()$availability_lots,
                                  " / ", df_filtered()$total_lots, "<br>",
                                  "<b>Carpark Type: </b>", df_filtered()$car_park_type, "<br>",
                                  "<b>Short Term Parking: </b>", df_filtered()$short_term_parking, "<br>",
                                  "<b>Free Parking: </b>", df_filtered()$free_parking, "<br>",
                                  "<b>Night Parking: </b>", df_filtered()$night_parking, "<br>",
                                  "<b>Last Update: </b>", df_filtered()$last_update),
                   color = ~pal(fill_percentage))
    }
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
  
  # Adding Legend
  observe({
    
    if (input$legend) {
      
      leafletProxy("map", data = df_latest) %>% 
        addLegend(position = "bottomright",
                  pal = pal,
                  values = ~fill_percentage,
                  title = "Availability",
                  labFormat = labelFormat(suffix = "%"),
                  opacity = 0.9)
    } else {
      
      leafletProxy("map", data = df_latest) %>%
        clearControls()
      
    }
  })
  
  # Reloading with latest data
  observe({
    
    if (input$refresh) {
      
      reloading_screen = Waiter$new(html = reloading_screen_bg,
                                    color = "#192841")
      reloading_screen$show()
      
      df_latest <<- pull_cp_avail()
      
      reloading_screen$hide()
    }
  })
}

# 4. Run the application 
shinyApp(ui = ui, server = server)

