library(googlesheets4)
library(mongolite)
library(logger)
library(openxlsx)
library(dplyr)
library(jsonlite)
library(stringr)
library(vctrs)
library(purrr)

stash_name <- "gsheet_archive"

mongo_url <- Sys.getenv(("MONGO_CONN_STRING"))
#' Write dataframe to mongodb as a dataset with meta data
#' 
#' Add meta data for source and creation date for the dataset.
#' 
#' @param df: datafrmae to be written
#' 

fetch_gsheet <-function(gsheet_url) {
  
  gs4_deauth()
  options(gargle_verbosity = "debug")
  gs4_auth(path =  ".secrets/hja-001-api-key.json")
  
  df <- read_sheet(gsheet_url, .name_repair = "unique")
  orig_names <- names(df)
    new_names <- orig_names |>
        vec_as_names( repair="universal", quiet=TRUE ) |>
        str_replace_all( "\\.", "_") |>
        str_replace_all( "_+", "_") |>
        str_replace("_$", "")
   names(df) = new_names 
   return(df)
}

stash_dataset_to_mongo <- function (df, db)  {
    coll = mongo(db=db, stash_name, url = mongo_url)
    dataset <- list(
        created = as.numeric(Sys.time()),
        source = "test",
        df = df
    )
    coll$insert(dataset)
}

get_latest <- function (coll_name) {
    coll = mongo(db=db_name, coll_name, url = mongo_url)
    latest <- coll$find(
        query = '{}',
        fields = '{}',
        sort = '{"_id":-1}',
        limit = 1
        )
    return(latest)
    }

get_latest_stash <- function() {
    stash <- get_latest(stash_name)
    return (stash)
}


get_sales_data <- function (sales_df) {
    result <- sales_df  |>
        group_by(SALES_PERSON)|>
        summarise(
            sales = sum(Is_this_a_sale_or_a_prospective_customer == "SALE"),
            prospects = sum(Is_this_a_sale_or_a_prospective_customer == "PROSPECT"),
            `500ml` = sum(`_500ml_bottles`),
            `1l` = sum(`_1_litre_bottles`),
            `5l` = sum(`_5_litre_bottles`),
            total_litres = sum ( 0.5*`500ml`, `1l`, 5*`5l`, na.rm=TRUE),
            payments = sum(Payment_made),
            deferred_payments = sum (Amount_left_to_pay),
            total_value = sum(payments)
        )

}

write_sales_xl <- function (df) {
    wb <- createWorkbook()
    addWorksheet(wb, "Sales")
    writeData(wb, "Sales", df, startCol=2, startRow=3, rownames+TRUE)
    saveWorkbook(wb, "data\\SalesData.xlsx", overwrite = TRUE)
}
get_crops_data <- function (df) {

    area_patterns <- list(".", "less", "1-2", "3")
    area_names <- list("All acreages", "Under 1 acre", "1-2 acres", "Above 2 acres")
    crop_data <-  df  |>
        select (starts_with("Crops_grown_with"))
    names(crop_data) = str_match(names(crop_data), "_OFA_(\\w+)")[,2]

    count_size  <- function (data, size_pattern) {
        result <- map_int(data, ~ (sum(str_detect(.x, size_pattern), na.rm=TRUE)))
        return(as.data.frame(result))
    }
#    count_size2  <- function (data, size_pattern, area_name) {
#        !!area_name <- map_int(data, ~ (sum(str_detect(.x, size_pattern), na.rm=TRUE)))
#        return(as.data.frame(!!area_name))
#    }
    #size_counts2 <- map2( area_patterns, area_names, ~ count_size2(crop_data,  .x, .y))  |>

    size_counts <- map( area_patterns,  ~ count_size(crop_data, .x))  |>
        list_cbind() 
    names(size_counts) = area_names
    size_counts <- size_counts  |>
        mutate(Crop = names(crop_data), .before=1)

    return(size_counts)
}


write_to_excel <- function (sales, crops, gsheet) {
    wb <- createWorkbook()

    add_sheet <- function(ws_name, df){
        addWorksheet(wb, ws_name)
        writeData(wb, ws_name, df, startCol=1, startRow=1, rownames+TRUE)
    }
    add_sheet("Sales", sales)
    add_sheet("Crops", crops)
    add_sheet("Google sheet", gsheet)
    
    log_info("Saving excel file")
    
    result <- saveWorkbook(wb, ".\\data\\SalesData.xlsx", overwrite = TRUE,
                           returnValue = TRUE)
    log_info("Saving excel file result: {result}")
}
# Return date in YYYYMMDDTHHMM format.
iso_datetime_short <- function () {
  format(Sys.time(), "%Y%m%dT%H%M")
}
