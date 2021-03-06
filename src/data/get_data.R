library(airportr)
data_loc <- '~/Documents/datasci_projects/nba-home-court-advantage/data/'

## GAME DATA
# Read in data from 538
file_loc <- 'https://projects.fivethirtyeight.com/nba-model/nba_elo.csv'
game_data <- read.csv(file_loc)

# Clean up some variables
game_data$date <- as.Date(game_data$date) 
game_data$playoff <- !(game_data$playoff == '')
game_data$game_uid <- 1:nrow(game_data)

write.csv(game_data, file=paste0(data_loc,'nba_game_outcomes.csv'),row.names=FALSE)



## NBA AIRPORT LOCATIONS
# Note this file was created by hand
file_loc <- '~/Documents/datasci_projects/nba-home-court-advantage/data/nba_team_history.csv'
nba_teams <- read.csv(file_loc)
nba_teams_since1990 <- nba_teams %>%
  filter((is.na(end) | end >= 1990) & city != "New Orleans/Oklahoma City")
df <- data.frame()
for (i in unique(nba_teams_since1990[,"city"])) {
  print(i)
  if (i %in% c("Vancouver", "Toronto")) {
    country = 'CA'
  } else {
    country = 'USA'
  }
  temp_df <- city_airports(i, country)
  temp_df <- temp_df[1,] # Keep first entry
  df <- rbind(df, temp_df)
}

colnames(df) <- tolower(colnames(df))

write.csv(df, file=paste0(data_loc,'nba_airport_locations.csv'), row.names = FALSE)
