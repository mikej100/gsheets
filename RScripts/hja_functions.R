library(googlesheets4)
library(mongolite)
library(dplyr)
library(jsonlite)
library(stringr)
library(vctrs)

stash_name <- "gsheet_archive"

mongo_url <- Sys.getenv(("MONGO_CONN_STRING"))
#' Write dataframe to mongodb as a dataset with meta data
#' 
#' Add meta data for source and creation date for the dataset.
#' 
#' @param df: datafrmae to be written
#' 

fetch_gsheet <-function(gsheet_url) {
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


# Return date in YYYYMMDDTHHMM format.
iso_datetime_short <- function () {
  format(Sys.time(), "%Y%m%dT%H%M")
}
