

con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35Wtest")
setequal(d_dbase %>% names, RPostgreSQL::dbListFields(con, 'movies'))
RPostgreSQL::dbGetQuery(chkc(con), "select TRUE;")
RPostgreSQL::dbGetQuery(chkc(con), "select * from r_version();")
RPostgreSQL::dbGetQuery(chkc(con), "select * from plr_version();")
RPostgreSQL::dbGetQuery(chkc(con), "select * from give_vector('[{\"tomato_url\": \"fight_club\", \"rating\": 8}]'::json);")

revs <- '\'[{"tomato_url":"robot-jox","rating":9},{"tomato_url":"fight_club","rating":10},{"tomato_url":"the_red_violin","rating":10},{"tomato_url":"meet_the_parents_1992","rating":2},{"tomato_url":"return_of_the_living_dead_3","rating":6},{"tomato_url":"hellraiser","rating":10},{"tomato_url":"ernest-scared-stupid","rating":8},{"tomato_url":"great_outdoors","rating":10},{"tomato_url":"american_beauty","rating":10},{"tomato_url":"the_addams_family","rating":10},{"tomato_url":"addams_family_values","rating":10},{"tomato_url":"stairway_to_heaven_1946","rating":8},{"tomato_url":"the_dark_knight","rating":10},{"tomato_url":"october_sky","rating":6},{"tomato_url":"meet_joe_black","rating":10},{"tomato_url":"star_trek_first_contact","rating":10},{"tomato_url":"1084146-thin_red_line","rating":6},{"tomato_url":"sister_act","rating":6},{"tomato_url":"40_year_old_virgin","rating":8}]::json'
qry_ <- sprintf("SELECT * from give_vector(%s);", revs)
RPostgreSQL::dbGetQuery(chkc(con), qry_)
RPostgreSQL::dbGetQuery(chkc(con), "select * from give_vector('[{\"tomato_url\": \"fight_club\", \"rating\": 8}]'::json);")
RPostgreSQL::dbGetQuery(chkc(con), "select * from give_vector(\"asldfkaf\");")

fromJSON('[{"tomato_url": "fight_club", "rating": 10}]')
