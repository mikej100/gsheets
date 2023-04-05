library(shiny)
library(googledrive)

# source("RScripts/ui.R")
# source("RScripts/server.R")
source("RScripts/hja_functions.R")

ui <- fluidPage(
  #kjselectInput("dataset", label="Dataset", choices = ls("package::datasets") ),
  
  selectInput("dataset", label="Dataset", choices = c("Sales", "Crops") ),
  downloadButton("downloadData", "Download"),
  verbatimTextOutput("summary"),
  tableOutput("table")
)

server <- function(input, output, session) {
   
  gsheet <- "https://docs.google.com/spreadsheets/d/1o_m0_WYgxvar2eLgUlTYNHwLEjRTuBy0U_yd1X-eSrI/edit?resourcekey#gid=1954067065"
  data <- fetch_gsheet(gsheet)
  sales <- get_sales_data(data)
  crops <<- get_crops_data(data)
  write_to_excel( sales, crops, gsheet)
  
  output$table <- renderTable(sales)
  
  output$downloadData <- downloadHandler(
    filename = "Test data.xlsx",
    content = function(file) {
      filename <- './data/Test data.xlsx'
      file.copy(filename, file)
    }
  )
}

shinyApp(ui = ui, server = server)

