source(file.path(getwd(), "00l-loaders.R"))

if (FALSE) {
  d_tos <- tos_load()
  d_rev <- rev_load()
  d_cov <- cov_load()
  d_mov <- mov_load()
  d_rot <- rot_load()
  
  # d_mov[str_detect(title, "(?i)spider")]
  
  d_rev[d_cov, on = c(surl = 'murl'), surl := i.surl]
  d_comb <- rbind(d_tos, d_rev, fill = T)
  rm_b <- duplicated(d_comb[, .(surl, uurl)])
  d_comb <- d_comb[!rm_b]; rm(rm_b)
  
  # d_comb[J(unlist(d_cov[1])), on = 'surl', nomatch = 0][, .N, surl]
  # d_comb[J(unlist(d_cov[1])), on = 'tomatourl', nomatch = 0][, .N, tomatourl]
  d_comb[d_mov, on = c(surl = 'tomatourl'), tomatourl := i.tomatourl]
  
  d_remains <- d_comb[is.na(tomatourl), by = 'surl', .N][order(-N)]
  # d_remains <- d_remains[!d_rot, on = 'surl']
  d_rot[d_remains, on = 'surl', N := i.N]
  setorder(d_rot, -N)
  
  d_mov[d_comb, on = c(tomatourl = 'surl'), surl := i.surl]
  d_remains <- d_mov[is.na(surl)]
  
  RE <- "(?i)(Dark |forgotten_)city"
  RE <- "(?i)dark_city"
  RE <- "(?i)I.*Robot"
  
  # "/m/down-syndrome-the-first-18-months2004"
  d_comb[str_detect(surl, RE)]
  d_comb[str_detect(surl, "(?i)down.syndrome")]
  d_rev[str_detect(surl, "(?i)down.syndrome")]
  d_tos[str_detect(surl, "(?i)down.syndrome")]
  
  d_mov[str_detect(title, "(?i)incredibles")]
  d_remains[str_detect(title, "(?i)incredibles")]
}


## Algorithm ###
d_tos <- tos_load()
d_rev <- rev_load()
d_cov <- cov_load()
d_mov <- mov_load()
d_rot <- rot_load()

# d_tos[str_detect(surl, "godfather"), unique(surl)]
# d_rev[str_detect(surl, "godfather"), unique(surl)]
d_rev[d_cov, on = c(surl = 'murl'), surl := i.surl]
d_comb <- rbind(d_tos, d_rev, fill = T)
rm_b <- duplicated(d_comb[, .(surl, uurl)], fromLast = T)
d_comb <- d_comb[!rm_b]; rm(rm_b)

d_comb[d_mov, on = c(surl = 'tomatourl'), tomatourl := i.tomatourl]
d_comb <- d_comb[!is.na(tomatourl), !'surl']
d_comb <- d_comb[!(is.na(rating) | rating == 0)]
d_comb[, uurl := str_remove(uurl, "/user/id/")]
d_comb[, tomatourl := str_remove(tomatourl, "/m/")]

setnames(d_comb, 'tomatourl', 'tomato_url')
setnames(d_mov, 'tomatourl', 'tomato_url')

d_mov[, tomato_url := str_remove(tomato_url, "/m/")]
d_mov[, year := as.integer(year)]


if (FALSE && sv) {
  # con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35WMoveRex")
  # RPostgreSQL::dbListTables(con)
  # RPostgreSQL::dbListFields(chkc(con), 'movies_movie')
  # # RPostgreSQL::dbDataType(chkc(con), 'movies_movie')
  # qry_ <- "
  #     SELECT column_name, data_type
  #     FROM information_schema.columns
  #     WHERE table_name = 'movies_movie';
  #     "
  # RPostgreSQL::dbGetQuery(chkc(con), qry_)
  # 
  # qry_ <- "SELECT * FROM movies_movie LIMIT 1;"
  # RPostgreSQL::dbGetQuery(chkc(con), qry_)
  
  d_dbase <- copy(d_mov)
  
  d_surl <- rbind(
    d_tos[, 'surl'],
    d_rev[, 'surl'],
    melt(copy(d_cov)[, i := .I], id.vars = 'i', value.name = 'surl')[, 'surl']
  )[, unique(.SD)]
  d_surl[, surl := str_remove(surl, "^/m/")]
  d_surl[, surl := str_remove(surl, "/$")]
  
  d_dbase[, tomato_url := str_remove(tomato_url, trim_url_RE)]
  d_dbase[, tomato_url := str_remove(tomato_url, "^/m/")]
  d_dbase[, tomato_url := str_remove(tomato_url, "/$")]
  d_dbase[, surl := tomato_url]
  
  d_dbase <- d_dbase[d_surl, on = 'surl', nomatch = 0][, !'surl']
  setcolorder(d_dbase, c('tomato_url'))
  
  if (!has.0rows(d_dbase[has.a_duplicate(tomato_url)])) {
    d_dbase[, dp_dx := duplicate_index(.SD), .SDc = c('tomato_url')]
    pick_dup <- \(SD) {
      if (is.na(get('.BY', envir = parent.frame()))) return(SD)
      return(SD[which.max(priority)])
    }
    d_dbase <- d_dbase[, by = 'dp_dx', pick_dup(.SD)]
    d_dbase[, dp_dx := NULL]
    setorder(d_dbase, -priority)
  }
  d_dbase[, runtime := str_remove(runtime, "[Ss]")]
  
  old_nms <-  c("tomato_url", "imdbid", "title", "year", "priority", "plot", 
                "runtime", "poster", "rated",  "metascore", "imdbrating",
                "tomatorating", "awards", "genre",  "director", "writer",
                "actors", "language")
  new_nms <- c("tomato_url", "imdb_id", "title", "year", "priority", "plot", 
               "runtime", "poster_url", "mpa_rating", "metascore", "imdb_rating", 
               "tomato_rating", "awards", "genres", "directors", "writers", 
               "actors", "languages")
  setnames(d_dbase, old_nms, new_nms)
  d_dbase <- d_dbase[, .SD, .SDc = new_nms]
  RPostgreSQL::dbWriteTable(chkc(con), 'movies_movie_refresh', overwrite = T, d_dbase)
  # qry_ <- "ALTER TABLE movies ADD PRIMARY KEY (tomato_url);"
  # RPostgreSQL::dbGetQuery(chkc(con), qry_)
  beepr::beep()
  
  # RPostgreSQL::dbListFields(chkc(con), 'movies_review')
  
  d_mov_ref <- d_dbase
  d_dbase <- copy(d_comb)
  d_dbase <- d_dbase[d_mov_ref[, 'tomato_url'], on = 'tomato_url', nomatch = 0]
  rm(d_mov_ref)
  
  # con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35Wtest")
  con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35WMoveRex")
  RPostgreSQL::dbWriteTable(chkc(con), 'movies_review_refresh', overwrite = T, d_dbase)
  # qry_ <- "ALTER TABLE reviews;" # ADD PRIMARY KEY (tomatourl)
  # RPostgreSQL::dbGetQuery(chkc(con), qry_)
  rm(d_dbase)
  # RPostgreSQL::dbGetQuery(chkc(con), "SELECT COUNT(*) FROM reviews")
  beepr::beep()
}

duplicated(d_comb[, .(uurl, tomato_url)]) %>% d_comb[.]

# d_ss <- copy(d_comb)[uurl == "/user/id/234686004"]
# duplicated(d_ss[, .(uurl, tomatourl)]) %>% d_ss[.]
# d_ss[, .(uurl, tomatourl)][str_detect(tomatourl, "ernest-scared-stupid")]
# d_mov[str_detect(title, "(?i)stairway"), unique(title)]

if (FALSE) {
  f_ <- function(x) {as.data.table(psych::describe(x))}
  d_stat <- d_comb[, by = 'tomato_url', f_(rating)]
  d_stat <- d_stat[50 > 1]
  
  
  d_stat[order(-sd)][n > 1000][, tomato_url][101:200] %>% paste(collapse = "\n") %>% cat
  
  
}


if (FALSE) {
  d_mov[1:2000, .SD, .SDc = 1:9] %>% tail(50)
  d_mov[str_detect(title, "(?i)virgin")]
}

rating_l <- list(
  c(title = "", year = NA_integer_, rating = NA_integer_), ## Placeholder ##
  c(title = "Robot Jox", rating = 9),
  c(title = "Fight Club", rating = 10),
  c(title = "The Red Violin", rating = 10),
  c(title = "Meet the Parents", rating = 2),
  c(title = "Return of the Living Dead III", rating = 6),
  c(title = "Hellraiser", rating = 10),
  c(title = "Ernest Scared Stupid", rating = 8),
  c(title = "The Great Outdoors", rating = 10),
  c(title = "American Beauty", rating = 10),
  c(title = "The Addams Family", rating = 10),
  c(title = "Addams Family Values", rating = 10),
  c(title = "Stairway to Heaven", rating = 8),
  c(title = "The Dark Knight", rating = 10),
  c(title = "October Sky", rating = 6),
  c(title = "Meet Joe Black", rating = 10),
  c(title = "Star Trek: First Contact", rating = 10),
  c(title = "The Thin Red Line", year = 1998, rating = 6),
  c(title = "Sister Act", rating = 6),
  c(title = "The 40-Year-Old Virgin", rating = 8)
)
d_target <- lapply(rating_l, \(x) as.data.table(as.list(x)))
d_target <- cbind(data.table(uurl = "me"), rbindlist(d_target, fill = T)[-1])
for (j in c('year','rating')) set(d_target, j = j, value = as.integer(d_target[[j]]))
d_target[d_mov, on = 'title', tomato_url := i.tomato_url]
d_target[d_mov, on = c('title','year'), tomato_url := i.tomato_url]

if (FALSE) {
  
  # SELECT * from give_vector('[{\"tomato_url\":\"robot-jox\",\"rating\":9},{\"tomato_url\":\"fight_club\",\"rating\":10},{\"tomato_url\":\"the_red_violin\",\"rating\":10},{\"tomato_url\":\"meet_the_parents_1992\",\"rating\":2},{\"tomato_url\":\"return_of_the_living_dead_3\",\"rating\":6},{\"tomato_url\":\"hellraiser\",\"rating\":10},{\"tomato_url\":\"ernest-scared-stupid\",\"rating\":8},{\"tomato_url\":\"great_outdoors\",\"rating\":10},{\"tomato_url\":\"american_beauty\",\"rating\":10},{\"tomato_url\":\"the_addams_family\",\"rating\":10},{\"tomato_url\":\"addams_family_values\",\"rating\":10},{\"tomato_url\":\"stairway_to_heaven_1946\",\"rating\":8},{\"tomato_url\":\"the_dark_knight\",\"rating\":10},{\"tomato_url\":\"october_sky\",\"rating\":6},{\"tomato_url\":\"meet_joe_black\",\"rating\":10},{\"tomato_url\":\"star_trek_first_contact\",\"rating\":10},{\"tomato_url\":\"1084146-thin_red_line\",\"rating\":6},{\"tomato_url\":\"sister_act\",\"rating\":6},{\"tomato_url\":\"40_year_old_virgin\",\"rating\":8}]'::json);
  
  
  # setnames(copy(d_target), 'tomatourl', 'tomato_url')[, .(tomato_url, rating)] %>% toJSON()
  revs <- '[{"tomato_url":"robot-jox","rating":9},{"tomato_url":"fight_club","rating":10},{"tomato_url":"the_red_violin","rating":10},{"tomato_url":"meet_the_parents_1992","rating":2},{"tomato_url":"return_of_the_living_dead_3","rating":6},{"tomato_url":"hellraiser","rating":10},{"tomato_url":"ernest-scared-stupid","rating":8},{"tomato_url":"great_outdoors","rating":10},{"tomato_url":"american_beauty","rating":10},{"tomato_url":"the_addams_family","rating":10},{"tomato_url":"addams_family_values","rating":10},{"tomato_url":"stairway_to_heaven_1946","rating":8},{"tomato_url":"the_dark_knight","rating":10},{"tomato_url":"october_sky","rating":6},{"tomato_url":"meet_joe_black","rating":10},{"tomato_url":"star_trek_first_contact","rating":10},{"tomato_url":"1084146-thin_red_line","rating":6},{"tomato_url":"sister_act","rating":6},{"tomato_url":"40_year_old_virgin","rating":8}]'
  revs <- '[{"tomato_url":"fight_club","rating":10},{"tomato_url":"pulp_fiction","rating":9},{"tomato_url":"shawshank_redemption","rating":10},{"tomato_url":"the_dark_knight","rating":5},{"tomato_url":"inception","rating":9},{"tomato_url":"matrix","rating":8},{"tomato_url":"interstellar_2014","rating":4},{"tomato_url":"saving_private_ryan","rating":7},{"tomato_url":"the_lion_king","rating":10},{"tomato_url":"star_wars","rating":9}]'
  revs <- '[{"tomato_url":"the-last-dragon","rating":9},{"tomato_url":"iron_giant","rating":10},{"tomato_url":"summer-wars","rating":8},{"tomato_url":"nausicaa_of_the_valley_of_the_wind","rating":9},{"tomato_url":"dragon_ball_z_resurrection_f","rating":8},{"tomato_url":"ready_player_one","rating":3}]'
  
  f_print <- function(obj) paste("\n", paste(capture.output(obj), sep = "\n", collapse = "\n"))
  pg.thrownotice <- cat
  d_ <- as.data.table(fromJSON(revs))
  pg.thrownotice(f_print(d_))
  
  qry_v <- paste0("'", paste(d_$tomato_url, collapse = "','"), "'")
  qry_ <- sprintf("SELECT * FROM reviews WHERE tomato_url IN (%s);", qry_v)
  
  
  d_target <- as.data.table(fromJSON(revs))[, uurl := 'me']
}

# if (FALSE) {
#   d_chigh <- copy(d_comb)[rating >= 9]
# } else {
#   d_chigh <- copy(d_comb)
# }

if (F) {
  movies_review <- copy(d_comb)
  movies_movie <- copy(d_mov)
  pg.thrownotice <- cat
  revs <- '[{"tomato_url":"the-last-dragon","rating":9},{"tomato_url":"iron_giant","rating":10},{"tomato_url":"summer-wars","rating":8},{"tomato_url":"nausicaa_of_the_valley_of_the_wind","rating":9},{"tomato_url":"dragon_ball_z_resurrection_f","rating":8},{"tomato_url":"ready_player_one","rating":3}]'
  
  revs <- '[{"tomato_url":"the-last-dragon","rating":9},{"tomato_url":"iron_giant","rating":10},{"tomato_url":"summer-wars","rating":8},{"tomato_url":"nausicaa_of_the_valley_of_the_wind","rating":9},{"tomato_url":"dragon_ball_z_resurrection_f","rating":8},{"tomato_url":"ready_player_one","rating":3}]'
  
  revs <- '[{"tomato_url":"slc_punk","rating":10},{"tomato_url":"starship_troopers","rating":9},{"tomato_url":"crow","rating":9},{"tomato_url":"fiddler_on_the_roof","rating":10},{"tomato_url":"event_horizon","rating":10},{"tomato_url":"no_country_for_old_men","rating":10},{"tomato_url":"robot-jox","rating":8},{"tomato_url":"meet_the_parents_1992","rating":2}]'
  
  revs <- '[{"tomato_url":"slc_punk","rating":10},{"tomato_url":"starship_troopers","rating":9},{"tomato_url":"crow","rating":9},{"tomato_url":"fiddler_on_the_roof","rating":10},{"tomato_url":"event_horizon","rating":10},{"tomato_url":"no_country_for_old_men","rating":10},{"tomato_url":"robot-jox","rating":8},{"tomato_url":"meet_the_parents_1992","rating":2},{"tomato_url":"a_fistful_of_dynamite","rating":0}]'
  revs <- '[{"tomato_url":"fight_club","rating":10}]'
  
  revs <- '[{"tomato_url":"robot-jox","rating":9},{"tomato_url":"fight_club","rating":10},{"tomato_url":"the_red_violin","rating":10},{"tomato_url":"meet_the_parents_1992","rating":2},{"tomato_url":"return_of_the_living_dead_3","rating":6},{"tomato_url":"hellraiser","rating":10},{"tomato_url":"ernest-scared-stupid","rating":8},{"tomato_url":"great_outdoors","rating":10},{"tomato_url":"american_beauty","rating":10},{"tomato_url":"the_addams_family","rating":10},{"tomato_url":"addams_family_values","rating":10},{"tomato_url":"stairway_to_heaven_1946","rating":8},{"tomato_url":"the_dark_knight","rating":10},{"tomato_url":"october_sky","rating":6},{"tomato_url":"meet_joe_black","rating":10},{"tomato_url":"star_trek_first_contact","rating":10},{"tomato_url":"1084146-thin_red_line","rating":6},{"tomato_url":"sister_act","rating":6},{"tomato_url":"40_year_old_virgin","rating":8},{"tomato_url":"slc_punk","rating":10},{"tomato_url":"starship_troopers","rating":9},{"tomato_url":"crow","rating":9},{"tomato_url":"fiddler_on_the_roof","rating":10},{"tomato_url":"event_horizon","rating":10},{"tomato_url":"no_country_for_old_men","rating":10},{"tomato_url":"there_will_be_blood","rating":10},{"tomato_url":"citizen_kane","rating":5},{"tomato_url":"dr_strangelove","rating":7},{"tomato_url":"iron_man_3","rating":6},{"tomato_url":"schindlers_list","rating":10},{"tomato_url":"matrix","rating":10},{"tomato_url":"memento","rating":5},{"tomato_url":"1003707-casablanca","rating":5},{"tomato_url":"1074316-scream","rating":6}]'

}

## get_recs() ####
get_recs <- function(revs) {
  ## pg.thrownotice(print(revs))
  f_print <- function(obj) paste("\n",paste(capture.output(obj), sep = "\n", collapse = "\n"))
  
  d_target <- as.data.table(fromJSON(revs))
  set(d_target, j = 'uurl', value = "me")
  trg_nms <- c('uurl','rating','tomato_url')
  d_target <- d_target[, .SD, .SDc = trg_nms]
  d_target <- d_target[!duplicated(tomato_url)]
  # pg.thrownotice(f_print(d_))
  ## -- qry_ <- "SELECT * FROM reviews WHERE tomato_url IN ('robot-jox')"
  
  d_exclude <- d_target[rating == 0L]
  d_target <- d_target[rating != 0L]
  
  qry_v <- paste0("'", paste(d_target$tomato_url, collapse = "','"), "'")
  qry_ <- sprintf("SELECT uurl, rating, tomato_url FROM movies_review WHERE tomato_url IN (%s)", qry_v)
  nn_ <- Sys.info()['nodename']
  d_ss <- if (nn_ != "JL-LBC1" || nn_ == "HS-WS-DS2") {
    as.data.table(sqldf::sqldf(qry_))
  } else {
    as.data.table(pg.spi.exec(qry_))
  }
  
  pg.thrownotice(f_print(nrow(d_ss)))
  
  lower_match_bound <- 20
  d_N <- d_ss[, .N, uurl][order(-N)]
  if (nrow(d_N) < lower_match_bound) lower_match_bound <- nrow(d_N)
  
  d_ss <- d_ss[d_N[N >= d_N[lower_match_bound, N], 'uurl'], on = 'uurl']
  
  qry_v <- paste0("'", paste(d_ss[, unique(uurl)], collapse = "','"), "'")
  qry_ <- sprintf("SELECT uurl, rating, tomato_url FROM movies_review WHERE uurl IN (%s) AND rating >= 9", qry_v)
  
  d_pool <- if (nn_ != "JL-LBC1" || nn_ == "HS-WS-DS2") {
    as.data.table(sqldf::sqldf(qry_))
  } else {
    as.data.table(pg.spi.exec(qry_))
  }
  setkey(d_pool, uurl)
  
  d_pool <- d_pool[!rbind(d_target, d_exclude), on = 'tomato_url']
  
  if (nrow(d_pool) == 0) {
    pg.thrownotice(f_print("d_pool nrow == 0, fallback"))
    return(c('fight_club','shawshank_redemption'))
  }
  
  pg.thrownotice(f_print(nrow(d_pool)))
  
  d_ss <- rbind(d_target[, .SD, .SDc = names(d_ss)], d_ss)
  d_cor <- dcast(d_ss, tomato_url ~ uurl, value.var = 'rating')
  ref_fld <- c('tomato_url','me')
  d_me <- d_cor[, .SD, .SDc = ref_fld]
  d_cor <- d_cor[, .SD, .SDc = !ref_fld]
  pg.thrownotice(f_print(nrow(d_cor)))
  
  n_store_min <- 100
  method <- 3
  switch(
    method, 
    '1' = {
      f_scr_vr <- function(x, y) (x - y) ^ 2
      d_scr <- d_cor[, lapply(.SD, f_scr_vr, x = d_me$me)]
      # pg.thrownotice(f_print(nrow(d_scr)))
      
      f_scr_mx  <- function(x) max(x, na.rm = T) # / (sum(!is.na(x)) - 1)
      d_max <- as.data.table(as.list(sapply(d_scr, f_scr_mx)))
      
      f_fill_na <- function(x, m) {
        b <- is.na(x)
        x[b] <- seq(sum(b)) + m
        x
      }
      d_scr[, names(d_scr) := mapply(f_fill_na, .SD, d_max, SIMPLIFY = F)]
      
      f_scr_sd  <- function(x) sum(x, na.rm = T) # / (sum(!is.na(x)) - 1)
      d_res <- as.data.table(as.list(sapply(d_scr, f_scr_sd)))
      
      d_tes <- transpose(d_res, keep.names = 'rn')[order(V1)]
      setnames(d_tes, 'V1', 'closeness')
      
      d_cls <- d_tes[!str_detect(rn, "me")]
      
      d_hold <- data.table()
      n_store <- 0
      for (i in seq(nrow(d_cls))) {  ##  i = 1  i = 2
        d_lp <- d_pool[d_cls[i], on = c(uurl = 'rn')][rating >= 9][, i := i]
        d_hold <- rbind(d_hold, d_lp)
        n_store <- n_store + nrow(d_hold)
        if (n_store > n_store_min) break #i > 50 &
        rm(list = ls(pattern = "_lp$"))
      }
      setorder(d_hold, -rating)
      d_hold <- d_hold[!duplicated(tomato_url)]
      
    },
    
    '2' = {
      # d_me[, weight := 1 + (10 - me) * .1]
      d_wgt <- as.data.table(list(me = 10:1, weight = c(3,2,1,0,1,2,4,8,16,32)))
      d_me[d_wgt, on = 'me', weight := i.weight]
      
      f_scr_vr <- function(x, y) (x - y) ^ 2
      d_scr <- d_cor[, lapply(.SD, f_scr_vr, x = d_me$me)]
      # pg.thrownotice(f_print(nrow(d_scr)))
      
      f_scr_mx  <- function(x) max(x, na.rm = T) # / (sum(!is.na(x)) - 1)
      d_max <- as.data.table(as.list(sapply(d_scr, f_scr_mx)))
      
      f_fill_na <- function(x, m, w) {
        b <- is.na(x)
        x[b] <- mean(seq(sum(b)) + m)
        x[b] <- x[b] + w[b]
        x
      }
      d_scr[, names(d_scr) := mapply(f_fill_na, .SD, d_max, SIMPLIFY = F, 
                                     MoreArgs = list(w = d_me[, weight]))]
      # d_scr <- d_scr * d_me[, weight]
      
      f_scr_sd  <- function(x) sum(x, na.rm = T) # / (sum(!is.na(x)) - 1)
      d_res <- as.data.table(as.list(sapply(d_scr, f_scr_sd)))
      
      d_tes <- transpose(d_res, keep.names = 'rn')[order(V1)]
      setnames(d_tes, 'V1', 'closeness')
      
      d_cls <- d_tes[!str_detect(rn, "me")]
      
      d_cls[, prop := 1 - (closeness - min(closeness)) / closeness]
      d_pool[d_cls, on = c(uurl = 'rn'), prop := i.prop]
      d_pool[, recog := rating * prop]
      
      d_hold <- d_pool[, by = 'tomato_url', .(recog = sum(recog))]
      setorder(d_hold, -recog)
      d_hold <- d_hold[1:n_store_min]
      
    },
    
    '3' = {
      
      d_wgt <- as.data.table(list(me = 10:1, weight = c(3,2,1,0,1,2,4,8,16,32)))
      d_me[d_wgt, on = 'me', weight := i.weight]
      
      f_scr_vr <- function(x, y) (x - y) ^ 2
      d_scr <- d_cor[, lapply(.SD, f_scr_vr, x = d_me$me)]
      # pg.thrownotice(f_print(nrow(d_scr)))
      
      f_scr_mx  <- function(x) max(x, na.rm = T) # / (sum(!is.na(x)) - 1)
      d_max <- as.data.table(as.list(sapply(d_scr, f_scr_mx)))
      
      f_fill_na <- function(x, m, w) {
        b <- is.na(x)
        x[b] <- mean(seq(sum(b)) + m)
        x[b] <- x[b] + w[b]
        x
      }
      d_scr[, names(d_scr) := mapply(f_fill_na, .SD, d_max, SIMPLIFY = F, 
                                     MoreArgs = list(w = d_me[, weight]))]
      # d_scr <- d_scr * d_me[, weight]
      
      f_scr_sd  <- function(x) sum(x, na.rm = T) # / (sum(!is.na(x)) - 1)
      d_res <- as.data.table(as.list(sapply(d_scr, f_scr_sd)))
      
      d_tes <- transpose(d_res, keep.names = 'rn')[order(V1)]
      setnames(d_tes, 'V1', 'closeness')
      
      d_cls <- d_tes[!str_detect(rn, "me")]
      
      d_cls[, prop := 1 - (closeness - min(closeness)) / closeness]
      d_pool[d_cls, on = c(uurl = 'rn'), prop := i.prop]
      d_pool[, recog := rating * prop]
      
      d_hold <- d_pool[, by = 'tomato_url', .(recog = sum(recog))]
      qry_v <- paste0("'", paste(d_hold[, unique(tomato_url)], collapse = "','"), "'")
      qry_ <- sprintf("SELECT priority, tomato_url FROM movies_movie WHERE tomato_url IN (%s)", qry_v)
      d_mov_vote <- if (nn_ != "JL-LBC1" || nn_ == "HS-WS-DS2") {
        as.data.table(sqldf::sqldf(qry_))
      } else {
        as.data.table(pg.spi.exec(qry_))
      }
      setkey(d_mov_vote, tomato_url)
      d_mov_vote[, prop_vn := 1 / priority]
      d_hold[d_mov_vote, on = 'tomato_url', prop_vn := i.prop_vn]
      d_hold[, final_weight := recog * prop_vn]
      setorder(d_hold, -final_weight)
      
      d_hold <- d_hold[1:n_store_min]
      
    }
  )
  
  
  return(d_hold$tomato_url)
}

if (FALSE) {
  # rbind(cbind(d_me, d_cor), d_buf, d_scr, d_buf, d_res, fill = T)
  top_nms <- d_tes[1:13, rn]
  top_nms <- union(p0('me', 5:7), top_nms)
  top_nms <- intersect(top_nms, names(d_cor))
  d1 <- cbind(d_me, d_cor[, .SD, .SDc = top_nms])
  d_buf <- d1[1, lapply(.SD, \(x) "")]
  d2 <- cbind(d_me[][, me := 0L], d_scr[, .SD, .SDc = top_nms])
  d3 <- d_res[, .SD, .SDc = top_nms]
  rbind(d1, d_buf, d2, d_buf, d3, fill = T)
}


d_ss <- d_chigh[d_target[, 'tomato_url'], on = 'tomato_url']
d_N <- d_ss[, .N, uurl][order(-N)]
# d_ss <- d_ss[uurl == "866550015", on = 'uurl']
# d_ss <- d_ss[uurl == "906669622", on = 'uurl']
# d_ss <- d_ss[d_N[1:10, 'uurl'], on = 'uurl']
d_ss <- d_ss[d_N[N >= 5, 'uurl'], on = 'uurl']
d_ss <- rbind(d_target[, .SD, .SDc = names(d_ss)], d_ss)
if (TRUE) {
  d_ss <- rbind(
    d_target[1:5, .SD, .SDc = names(d_ss)][, uurl := "me5"],
    d_target[1:6, .SD, .SDc = names(d_ss)][, uurl := "me6"],
    d_target[1:7, .SD, .SDc = names(d_ss)][, uurl := "me7"],
    d_ss)
}
d_cor <- dcast(d_ss, tomato_url ~ uurl, value.var = 'rating')
ref_fld <- c('tomato_url','me')
d_me <- d_cor[, .SD, .SDc = ref_fld]
d_cor <- d_cor[, .SD, .SDc = !ref_fld]
# scr_agree <- \(x, y) 10 - abs(x - y)
f_scr_vr <- \(x, y) (x - y) ^ 2
d_scr <- d_cor[, lapply(.SD, f_scr_vr, x = d_me$me)]
# d_scr[, .SD, .SDc = 1:10]
f_scr_mx  <- \(x) max(x, na.rm = T) # / (sum(!is.na(x)) - 1)
d_max <- as.data.table(as.list(sapply(d_scr, f_scr_mx)))
# j <- 0
# f_fill_na <- \(x, m) {
#   # j <- get('j', parent.frame())
#   # cat(j, "\n")
#   # assign('j', j + 1L, parent.frame())
#   # browser(expr = j == 18L)
#   x_ <- x[is.na(x)]
#   if (length(x_) == 1L && is.na(x_)) x_ <- 1L
#   x[is.na(x)] <- seq(x_) + m; x
# }
f_fill_na <- \(x, m) {b <- is.na(x); x[b] <- seq(sum(b)) + m; x}
d_scr[, names(d_scr) := mapply(f_fill_na, .SD, d_max, SIMPLIFY = F)]
f_scr_sd  <- \(x) sum(x, na.rm = T) # / (sum(!is.na(x)) - 1)
d_res <- as.data.table(as.list(sapply(d_scr, f_scr_sd)))
d_buf <- d_res[, lapply(.SD, \(x) "")]
##TODO: Improve this so that it scores closer for more values ##
d_tes <- transpose(d_res, keep.names = 'rn')[order(V1)]
setnames(d_tes, 'V1', 'closeness')

if (FALSE) {
  # rbind(cbind(d_me, d_cor), d_buf, d_scr, d_buf, d_res, fill = T)
  top_nms <- d_tes[1:13, rn]
  top_nms <- union(p0('me', 5:7), top_nms)
  d1 <- cbind(d_me, d_cor[, .SD, .SDc = top_nms])
  d_buf <- d1[1, lapply(.SD, \(x) "")]
  d2 <- cbind(d_me[][, me := 0L], d_scr[, .SD, .SDc = top_nms])
  d3 <- d_res[, .SD, .SDc = top_nms]
  rbind(d1, d_buf, d2, d_buf, d3, fill = T)
}

# d_ss[uurl == "/user/id/234686004"]
# dcast(d_ss, tomato_url ~ uurl, value.var = 'rating')
if (FALSE) {
  setcolorder(d_cor, 'me')
  N_mov <- length(rating_l)
  res_l <- Hmisc::rcorr(as.matrix(d_cor), type = "pearson")[c('r','n')]
  res_l <- append(list(uurl = row.names(res_l$r)), lapply(res_l, \(x) x[, 'me']))
  d_res <- as.data.table(res_l)[uurl != "me"]
  N_mov
  setorder(d_res, -r)
}

if (FALSE) {
  setkey(d_chigh, uurl)
  d_cls <- d_tes[!str_detect(rn, "me")]
  d_hold <- data.table()
  n_store <- 0
  for (i in seq(nrow(d_cls))) {  ##  i = 1  i = 2
    d_lp <- d_chigh[d_cls[i], on = c(uurl = 'rn')][rating >= 9][, i := i]
    d_hold <- rbind(d_hold, d_lp)
    n_store <- n_store + nrow(d_hold)
    if (n_store > 100) break #i > 50 &
    rm(list = ls(pattern = "_lp$"))
  }
  setorder(d_hold, -rating)
  
  d_ans <- d_hold[1:100]
  
  d_hold[tomato_url == "the_dark_knight", 1 / closeness]
  d_hold[tomato_url == "the_dark_knight"]
  
  d_hold[, .N, tomato_url][order(-N)]
  
  con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35Wtest")
  
  x <- '[{"tomato_url":"fight_club","rating":10}]' %>% fromJSON()
  unclass(x)
  
  toJSON(x)
  
  
  
  con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35Wtest")
  RPostgreSQL::dbGetQuery(chkc(con), "select TRUE;")
  RPostgreSQL::dbGetQuery(chkc(con), "select * from r_version();")
  RPostgreSQL::dbGetQuery(chkc(con), "select * from plr_version();")
  RPostgreSQL::dbGetQuery(chkc(con), "select * from give_vector('[{\"tomato_url\": \"fight_club\", \"rating\": 8}]'::json);")
  
  # select * from give_vector();
  # revs <- search()
  # pg.thrownotice("see this ")
  
  
}

if (FALSE) {
  ss <- T
  pg.thrownotice(ls(all.names = T)) #; if (ss) 
  pg.thrownotice(ls.str(envir = environment(), all.names = T))
  pg.thrownotice(ls(envir = parent.frame(1), all.names = T)) #; if (ss) 
  pg.thrownotice(ls.str(envir = parent.frame(1), all.names = T))
  pg.thrownotice(ls(envir = parent.frame(2), all.names = T)) #; if (ss) 
  pg.thrownotice(ls.str(envir = parent.frame(2), all.names = T))
  ls(envir = parent.frame(3), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(3), all.names = T)
  ls(envir = parent.frame(4), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(4), all.names = T)
  ls(envir = parent.frame(5), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(5), all.names = T)
  ls(envir = parent.frame(6), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(6), all.names = T)
  ls(envir = parent.frame(7), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(7), all.names = T)
  ls(envir = parent.frame(8), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(8), all.names = T)
  ls(envir = parent.frame(9), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(9), all.names = T)
  ls(envir = parent.frame(10), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(10), all.names = T)
  ls(envir = parent.frame(11), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(11), all.names = T)
  ls(envir = parent.frame(12), all.names = T) #; if (ss) 
  ls.str(envir = parent.frame(12), all.names = T)
  
  
  pg.thrownotice(try(ls(envir = sys.frames()[[12]]), silent = F))
  pg.thrownotice(ls.str(envir = sys.frames()[[12]], all.names = T))
  pg.thrownotice(try(ls(envir = sys.frames()[[11]]), silent = F))
  pg.thrownotice(ls.str(envir = sys.frames()[[11]], all.names = T))
  pg.thrownotice(try(ls(envir = sys.frames()[[10]]), silent = F))
  pg.thrownotice(ls.str(envir = sys.frames()[[10]], all.names = T))
  pg.thrownotice(try(ls(envir = sys.frames()[[9]]), silent = F))
  pg.thrownotice(ls.str(envir = sys.frames()[[9]], all.names = T))
  try(ls(envir = sys.frames()[[8]]), silent = F)
  ls.str(envir = sys.frames()[[8]], all.names = T)
  try(ls(envir = sys.frames()[[7]]), silent = F)
  ls.str(envir = sys.frames()[[7]], all.names = T)
  try(ls(envir = sys.frames()[[6]]), silent = F)
  ls.str(envir = sys.frames()[[6]], all.names = T)
  try(ls(envir = sys.frames()[[5]]), silent = F)
  ls.str(envir = sys.frames()[[5]], all.names = T)
  try(ls(envir = sys.frames()[[4]]), silent = F)
  ls.str(envir = sys.frames()[[4]], all.names = T)
  try(ls(envir = sys.frames()[[3]]), silent = F)
  ls.str(envir = sys.frames()[[3]], all.names = T)
  try(ls(envir = sys.frames()[[2]]), silent = F)
  ls.str(envir = sys.frames()[[2]], all.names = T)
  try(ls(envir = sys.frames()[[1]]), silent = F)
  ls.str(envir = sys.frames()[[1]], all.names = T)
  f <- function() {
    print(sys.calls())
    print(sys.frames())
    print(sys.frames())
    return(NULL)
  }
}