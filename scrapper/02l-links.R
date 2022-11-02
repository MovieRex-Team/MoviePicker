source(file.path(getwd(), "00l-loaders.R"))

d_mov <- mov_load()
d_mov <- d_mov[!is.na(tomatourl)]
d_mov <- d_mov[imdbvotes > 200]
# d <- d[str_detect(language, "(?i)english")]
# d <- d[, 'tomatourl']

d_rev <- rev_load()
d_rev[d_mov, on = c(surl = 'tomatourl'), tomatourl := i.tomatourl]
d_surl <-  d_rev[!is.na(tomatourl), !c('uurl','rating')][, unique(.SD)]
d_surl[, fix := FALSE]
d_mov[d_surl, on = c(tomatourl = 'surl'), fix := i.fix]
d_mov[is.na(fix), fix := TRUE]
d_fix <- d_mov[(fix)]

d_cov <- cov_load()
d_fix[d_cov, on = c(tomatourl = 'surl'), fix := FALSE]
d_fix <- d_fix[(fix)]

if (F) {
  # rd <- remDr
  surl <- "/m/star_wars/"
  surl <- "/m/interstellar_2014/"
  surl <- "/m/balkanski_spijun/"
  surl <- "/m/asdfaf"
  sv = FALSE; v = TRUE
}
link_conversion <- function(surl, data_file, sv = FALSE, v = FALSE) {#rd, 
  trim_txt <- "https://www.rottentomatoes.com"
  nav_url <- paste0(trim_txt, surl)
  l_lp <- list(surl = surl, murl = "")
  murl <- NULL
  try(murl <- httr::GET(nav_url, httr::timeout(5))$url, silent = T)
  if (!is.null(murl)) {
    l_lp$murl <- str_remove(murl, trim_txt)
    if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
    return(l_lp)
  }
  return(l_lp)
}

for (i in seq(nrow(d_fix))) {  # i =1
  d_lp <- d_fix[i]
  res_lp <- link_conversion(d_lp$tomatourl, conversion_file, sv = T) #remDr, 
  fmt_lp <- "'%s' (%s): '%s' to '%s'\n"
  msg_lp <- sprintf(fmt_lp, d_lp$title, d_lp$year, res_lp$surl, res_lp$murl)
  cat(msg_lp)
  rm(list = ls(pattern = "_lp$"))
}
