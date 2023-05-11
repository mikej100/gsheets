library(shiny)
library(googledrive)
library(logger)

# source("RScripts/ui.R")
# source("RScripts/server.R")
source("RScripts/hja_functions.R")
source("RScripts/config.R")

ui <- fluidPage(
  #kjselectInput("dataset", label="Dataset", choices = ls("package::datasets") ),
  titlePanel("HJA Sales form data report - dev0.2"),
  
#  sidebarPanel( ), 

  mainPanel(
    selectInput("dataset", label="Dataset", choices = c("Sales", "Crops") ),
    downloadButton("downloadData", "Download full data"),
    
    
    verbatimTextOutput("summary"),
    tableOutput("table"),
#    textOutput("debug")
  )
)

server <- function(input, output, session) {
   
  # gsheet_url <- "https://docs.google.com/spreadsheets/d/1o_m0_WYgxvar2eLgUlTYNHwLEjRTuBy0U_yd1X-eSrI/edit?resourcekey#gid=1954067065"
  gsheet_url <- cfg$gsheet_url
  data <- fetch_gsheet(gsheet_url)
  Sales <- get_sales_data(data)
  Crops <- get_crops_data(data)
  tables <- list(Sales=Sales, Crops=Crops)
  write_to_excel( Sales, Crops, data)
  
  #reactive(log_info("input$dataset: {input$dataset}"))
  #output$table <- renderTable(input$dataset)
  output$debug <- renderText(paste("input$dataset", {input$dataset}))
  output$table <- renderTable(tables[[{input$dataset}]])
  
  output$downloadData <- downloadHandler(
    filename = "SalesData.xlsx",
    content = function(file) {
      log_info("Download handler content function invoked")
      filename <- '.\\data\\SalesData.xlsx'
      result <- file.copy(filename, file, overwrite = TRUE)
      log_info("Result of file copy: {result}")
    }
  )
}

shinyApp(ui = ui, server = server)

