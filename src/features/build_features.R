library(dplyr)
source('~/Documents/datasci_projects/nba-home-court-advantage/src/features/feature_utils.R')

data_loc <- '~/Documents/datasci_projects/nba-home-court-advantage/data/'
nba_games <- read.csv(file=paste0(data_loc,'nba_game_outcomes.csv'))

# Prep Airport data
# city, latitude longitude altitude team
airport_mapping <- read.csv(file=paste0(data_loc,'nba_team_airport_mapping.csv')) %>%
  rename(location = team)
airport_locations <- read.csv(file=paste0(data_loc,'nba_airport_locations.csv')) %>%
  select(city, latitude, longitude, altitude)
airport_locations <- merge(airport_locations, airport_mapping, by.x= 'city', by.y = 'airport')
  


# NBA Outcomes

# Games: team, opponent, home, result date, location, prior.location , distance_traveled

start_season <- 1990
end_season <- 2019

nba_games <- nba_games %>% 
  filter(season >= start_season & season <= end_season & neutral == 0 & !is.na(score1) ) %>%
  select(c(date, season, playoff, team1, team2, score1, score2, game_uid)) %>%
  mutate(result1 = as.integer(score1 > score2),
         result2 = as.integer(score1 < score2), 
         location = team1)

game_info <- nba_games %>%
  select(game_uid, date, location)

# Home Teams
df_home <-  nba_games %>% 
  select(c(date, season, playoff, location, team1, score1, team2, result1, game_uid)) %>%
  rename(team = team1, score = score1, result = result1, opponent = team2)

# Away Teams
df_away <-  nba_games %>% 
  select(c(date, season, playoff, location, team2, score2, result2, team1, game_uid)) %>%
  rename(team = team2, score = score2, result = result2, opponent = team1)

df <- rbind(df_home, df_away) 

df <- df %>%
  arrange(team, season, date) %>%
  group_by(team, season) %>%
  mutate(date = as.Date(date)) %>%
  mutate(prior_date = lag(date, order_by=date),
         prior_location = lag(location, order_by=date),
         home = as.integer(team == location),
         days_rest = as.integer(date - prior_date))

# Impute travel schedule 
df <- df %>%
  mutate(prior_location = case_when(days_rest >= 5 ~ team,
            is.na(days_rest) ~ team,
            TRUE ~ prior_location)) %>%
  arrange(team, season, date)


df <- merge(x = df, y = airport_locations[,c("latitude","longitude","altitude","location")], by="location")
df <- merge(x = df, y = airport_locations[,c("latitude","longitude","location")], by.x = "prior_location", by.y = "location", suffixes = c("", ".prior"))
df$distance <- apply(df[,c('latitude.prior','longitude.prior', 'latitude','longitude')], 1, function(x) meters_to_miles(my_dist(x[1],x[2],x[3],x[4])))

drop_cols <- c("latitude", "longitude", "longitude.prior", "latitude.prior", "prior_date")
df <- df %>%
  select(-drop_cols) %>%
  arrange(team, season, date)

for (col in c("team", "opponent")) {
  df[,col] <- as.factor(df[,col])
}

print(head(df))

#Write final output
data_loc <- '~/Documents/datasci_projects/nba-home-court-advantage/data/'
write.csv(df, file=paste0(data_loc,'nba_game_cleaned.csv'))
