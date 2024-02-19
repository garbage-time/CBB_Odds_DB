# Load necessary libraries
library(DBI)
library(RSQLite)
remotes::install_github("sportsdataverse/oddsapiR")
library(oddsapiR)
library(dplyr)
library(stringr)

# Assert wd
stopifnot(stringr::word(getwd(), sep = "/", -1) ==  "CBB_Odds_DB")

# Define the database file
db_file <- "cbb_odds_db.sqlite"

# Connect to database
con <- dbConnect(RSQLite::SQLite(), db_file)

# Fetch the basketball spread data
spreads <- oddsapiR::toa_sports_odds("basketball_ncaab", markets = "spreads")
odds    <- oddsapiR::toa_sports_odds("basketball_ncaab", markets = "h2h")
totals  <- oddsapiR::toa_sports_odds("basketball_ncaab", markets = "totals")

# Rbind everything:
data <- data.table::rbindlist(list(spreads, odds, totals), fill = TRUE)

# Remove duplicate rows
data <- distinct(data)

# If the table already exists, load the existing data and append the new data
if(dbExistsTable(con, "basketball_spreads")) {
  existing_data <- dbReadTable(con, "basketball_odds")
  data <- rbind(existing_data, data)
  
  # Remove duplicates again in case new data duplicates existing data
  data <- distinct(data)
}

# Write the data into the SQLite database
dbWriteTable(con, "basketball_odds", as.data.frame(data), overwrite = TRUE)

# Close the database connection
dbDisconnect(con)
