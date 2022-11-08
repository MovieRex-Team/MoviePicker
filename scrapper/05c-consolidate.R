wd <- normalizePath(file.path(rstudioapi::documentPath(),".."))
setwd(wd)
source(file.path(getwd(), "00l-loaders.R"))

d_tos <- tos_load()
d_rev <- rev_load()
d_cov <- cov_load()
# d_mov <- mov_load()
d_rot <- rot_load()

# d_tos[str_detect(surl, "godfather"), unique(surl)]
# d_rev[str_detect(surl, "godfather"), unique(surl)]
d_rev[d_cov, on = c(surl = 'murl'), surl := i.surl]

# d_comb[d_mov, on = c(surl = 'tomatourl'), imdbid := i.imdbid]
d_comb <- rbind(d_tos, d_rev, fill = T)
rm_b <- duplicated(d_comb[, .(surl, uurl)])
d_comb <- d_comb[!rm_b]; rm(rm_b)


# d_comb[J(unlist(d_cov[1])), on = 'surl', nomatch = 0][, .N, surl]
# d_comb[J(unlist(d_cov[1])), on = 'tomatourl', nomatch = 0][, .N, tomatourl]
d_comb[d_mov, on = c(surl = 'tomatourl'), tomatourl := i.tomatourl]
## Not found linkable with d_mov ##
# d_remains <- d_comb[is.na(tomatourl), by = 'surl', .N][order(-N)]
## All found in d_mov ##
d_remains <- d_comb[!is.na(tomatourl), by = 'surl', .N][order(-N)]
d_remains <- d_remains[!d_rot, on = 'surl']

if (F) {
  surl <- ""
  surl <- "/m/incredibles"
  surl <- "/m/vares_yksityisetsiva"
  data_file <- rotten_file
}

scrap_tomatos <- function(surl, data_file, sv = TRUE, v = FALSE) {
  trim_txt <- "https://www.rottentomatoes.com"
  nav_url <- paste0(trim_txt, surl)
  l_lp <- list(surl = surl)
  if (is.na(surl) || surl == "") {
    if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
    return(l_lp)
  }
  err <- tryCatch({
    req <- httr::GET(nav_url, httr::timeout(5))
    pg_xml <- httr::content(req, as = "parsed")
  }, error = function(e) e)
  if (inherits(err, "error")) {
    if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
    return(l_lp)
  }
  # data_lp = rawToChar(req$content)
  # sl <- str_locate_all(data_lp, "PG")[[1]]
  # substring(data_lp, sl[,1]-180, sl[,2]+40)
  
  title_xp <- "//h1[@class='scoreboard__title']"
  title_xml <- xml2::xml_find_all(pg_xml, title_xp)
  title <- xml2::xml_text(title_xml)
  if (length(title) && !is.na(title)) l_lp$title <- title
  
  scr_brd_xp <- "//p[@class='scoreboard__info']"
  scr_brd_xml <- xml2::xml_find_all(pg_xml, scr_brd_xp)
  scr_brd <- xml2::xml_text(scr_brd_xml)
  if (length(scr_brd) && !is.na(scr_brd)) l_lp$scr_brd <- scr_brd
  
  hdr_xp <- "//score-board[@class='scoreboard']"
  hdr_xml <- xml2::xml_find_all(pg_xml, hdr_xp)
  hdr_attr <- character()
  try(hdr_attr <- xml2::xml_attrs(hdr_xml)[[1]], silent = T)
  attr_nms <- c('audiencescore','rating','tomatometerscore')
  attr_nms <- intersect(attr_nms, names(hdr_attr))
  if (length(attr_nms)) for (an in attr_nms) l_lp[[an]] <- unname(hdr_attr[an])
  
  poster_xp <- "//img[@class='posterImage']"
  poster_xml <- xml2::xml_find_all(pg_xml, poster_xp)
  poster <- xml2::xml_attr(poster_xml, 'src')
  if (length(poster) && !is.na(poster)) l_lp$poster <- poster
  if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
  return(l_lp)
}

for (i in seq(nrow(d_remains))) {  #  i=1  i=308
  cat("tomatourl: ", d_remains[i, surl], " with", d_remains[i, N], "entries.\n")
  scrap_tomatos(
    surl = d_remains[i, surl],
    data_file = rotten_file,
    sv = T
  )
  Sys.sleep(0.1)
}

