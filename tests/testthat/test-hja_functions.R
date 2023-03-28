library(testthat)
library(dplyr)
library(purrr)
source("./RScripts/hja_functions.R")


gsheet_url <-"https://docs.google.com/spreadsheets/d/1i3xAVax8JWvL8iNcU28QNP3ErnkvdIDT_iXAXRDd7OM/edit?resourcekey#gid=426554005"

# Sheet for Copy of HJA-sales-dev0.1_Stash_20230314 (Responses)
test2_gsheet <- "https://docs.google.com/spreadsheets/d/1o_m0_WYgxvar2eLgUlTYNHwLEjRTuBy0U_yd1X-eSrI/edit?resourcekey#gid=1954067065"
#
db_name <- "hja_dev0_1"
gsheet <- test2_gsheet

test_that("Retrieves data from googlesheets", {
    test_df <<- fetch_gsheet(gsheet )
    expect_is(test_df, "data.frame")
    expect_gte(length(test_df), 5,"number of columns")
    expect_gte(length(test_df[[1]]), 5,  "number of rows")
})

test_that("Insert and retrieve googlesheet data in MongoDB", {
    result <- stash_dataset_to_mongo(test_df, db_name) 

    mongo_ds <- get_latest_stash()
    mongo_df <<- mongo_ds$df[[1]]

    expect_is(mongo_df, "data.frame")
    expect_equal(mongo_df$CUSTOMER_NAME, test_df$CUSTOMER_NAME)
})

test_that("create sales summary from data", {
    sales <<- get_sales_data(test_df)
    expect_equal( sales[sales$SALES_PERSON=="Sales One", "sales"][[1]], 2)

    write_sales_xl(sales)
})

test_that("create crops summsary from gsheet", {
    crops <<- get_crops_data(test_df)
    expect_equal( crops[crops$Crop=="Cocoa", "All acreages"][[1]], 2)
})

write_to_excel( sales, crops, test_df)
