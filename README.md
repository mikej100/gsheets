# gsheets
Utility to process Google Sheets data and produce digested set of data in Excel data workbook which the user can download.

The utility is accessed by the user as a ShinyApp. Data is retreived from a pre-defined Google Sheet and presented in two summary
forms: one for sales and one for crops. The use can download an excel spreadsheet containing the two reports as well as the raw data.

Installation
============

Set the location of the Google Sheets in file ./app.R by assigning the url to variable gsheet_url

Create a service account in Google Cloud and generate api-key.json file. Put copy of 
api-key file in ./.secrets/ folder. In file 


