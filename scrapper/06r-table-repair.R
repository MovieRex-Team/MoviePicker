source(file.path(getwd(), "00l-loaders.R"))

d_tos <- tos_load()
d_rev <- rev_load()
d_cov <- cov_load()
d_mov <- mov_load()
d_rot <- rot_load()

d_mov[str_detect(title, "(?i)spider")]

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


