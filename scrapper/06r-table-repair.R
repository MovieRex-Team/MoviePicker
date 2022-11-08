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
rm_b <- duplicated(d_comb[, .(surl, uurl)])
d_comb <- d_comb[!rm_b]; rm(rm_b)

d_comb[d_mov, on = c(surl = 'tomatourl'), tomatourl := i.tomatourl]
d_comb <- d_comb[!is.na(tomatourl), !'surl']
d_comb <- d_comb[!(is.na(rating) | rating == 0)]
d_comb[, uurl := str_remove(uurl, "/user/id/")]
d_comb[, tomatourl := str_remove(tomatourl, "/m/")]

if (sv) {
  d_dbase <- copy(d_comb)
  con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35Wtest")
  RPostgreSQL::dbWriteTable(chkc(con), 'reviews', overwrite = TRUE, d_dbase)
  qry_ <- "ALTER TABLE reviews;" # ADD PRIMARY KEY (tomatourl)
  RPostgreSQL::dbGetQuery(chkc(con), qry_)
  rm(d_dbase)
  RPostgreSQL::dbGetQuery(chkc(con), "SELECT COUNT(*) FROM reviews")
}
duplicated(d_comb[, .(uurl, tomatourl)]) %>% d_comb[.]

# d_ss <- copy(d_comb)[uurl == "/user/id/234686004"]
# duplicated(d_ss[, .(uurl, tomatourl)]) %>% d_ss[.]
# d_ss[, .(uurl, tomatourl)][str_detect(tomatourl, "ernest-scared-stupid")]
# d_mov[str_detect(title, "(?i)stairway"), unique(title)]
d_mov[, tomatourl := str_remove(tomatourl, "/m/")]
d_mov[, year := as.integer(year)]

if (FALSE) {
  d_mov[1:2000, .SD, .SDc = 1:9] %>% tail(50)
  d_mov[str_detect(title, "(?i)thin red")]
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
  c(title = "The Thin Red Line", year = 1998, rating = 6)
)
d_target <- lapply(rating_l, \(x) as.data.table(as.list(x)))
d_target <- cbind(data.table(uurl = "me"), rbindlist(d_target, fill = T)[-1])
for (j in c('year','rating')) set(d_target, j = j, value = as.integer(d_target[[j]]))
d_target[d_mov, on = 'title', tomatourl := i.tomatourl]
d_target[d_mov, on = c('title','year'), tomatourl := i.tomatourl]

d_ss <- d_comb[d_target[, 'tomatourl'], on = 'tomatourl']
d_N <- d_ss[, .N, uurl][order(-N)]
# d_ss <- d_ss[uurl == "866550015", on = 'uurl']
# d_ss <- d_ss[uurl == "906669622", on = 'uurl']
# d_ss <- d_ss[d_N[1:10, 'uurl'], on = 'uurl']
d_ss <- d_ss[d_N[N > 4, 'uurl'], on = 'uurl']
d_ss <- rbind(d_target[, .SD, .SDc = names(d_ss)], d_ss)
if (TRUE) {
  d_ss <- rbind(
    d_target[1:5, .SD, .SDc = names(d_ss)][, uurl := "me5"],
    d_target[1:6, .SD, .SDc = names(d_ss)][, uurl := "me6"],
    d_target[1:7, .SD, .SDc = names(d_ss)][, uurl := "me7"],
    d_ss)
}

d_cor <- dcast(d_ss, tomatourl ~ uurl, value.var = 'rating')
ref_fld <- c('tomatourl','me')
d_me <- d_cor[, .SD, .SDc = ref_fld]
d_cor <- d_cor[, .SD, .SDc = !ref_fld]
# scr_agree <- \(x, y) 10 - abs(x - y)
scr_vr <- \(x, y) (x - y) ^ 2
d_scr <- d_cor[, lapply(.SD, scr_vr, x = d_me$me)]
# scr_sd  <- \(x) sum(x, na.rm = T) / log(sum(!is.na(x)))
scr_sd  <- \(x) sum(x, na.rm = T) / (sum(!is.na(x)) - 1)
d_res <- as.data.table(as.list(sapply(d_scr, scr_sd)))
d_buf <- d_res[, lapply(.SD, \(x) "")]

##TODO: Improve this so that it scores closer for more values ##
d_tes <- transpose(d_res, keep.names = 'rn')[order(V1)]

# rbind(cbind(d_me, d_cor), d_buf, d_scr, d_buf, d_res, fill = T)
top_nms <- d_tes[1:10, rn]
top_nms <- union(p0('me', 5:7), top_nms)
d1 <- cbind(d_me, d_cor[, .SD, .SDc = top_nms])
d_buf <- d1[1, lapply(.SD, \(x) "")]
d2 <- cbind(d_me[][, me := 0L], d_scr[, .SD, .SDc = top_nms])
d3 <- d_res[, .SD, .SDc = top_nms]
rbind(d1, d_buf, d2, d_buf, d3, fill = T)

# d_ss[uurl == "/user/id/234686004"]
# dcast(d_ss, tomatourl ~ uurl, value.var = 'rating')

setcolorder(d_cor, 'me')
N_mov <- length(rating_l)
res_l <- Hmisc::rcorr(as.matrix(d_cor), type = "pearson")[c('r','n')]
res_l <- append(list(uurl = row.names(res_l$r)), lapply(res_l, \(x) x[, 'me']))
d_res <- as.data.table(res_l)[uurl != "me"]

N_mov
setorder(d_res, -r)
