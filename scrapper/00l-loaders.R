source(file.path(getwd(), "00s-tools.R"))

## Load tos - tomatos ####
if (F) file_list = file.path(sav_loc, "tomatos2c.txt")
tos_load <- function(file_list = tomato2_files) {
  d_data <- data.table(raw = character(), i = integer(), fn = character())
  for (tom in file_list) { ##  tom=tom_fl[1]  tom=tom_fl[2]
    fn_lp <- str_extract(tom, "(?<=[\\\\/])[^\\\\/]+(?=\\.[[:alnum:]]{1,10}$)")
    d_lp <- f_read_lines(tom)[[1]][, fn := fn_lp]
    d_data <- rbind(d_data, d_lp, fill = T)
    rm(list = ls(pattern = "_lp$"))
  }
  if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
  d_data[, JSON := rep(list(), .N)]
  # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
  d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
  f_asDT <- \(l) {
    d <- as.data.table(l)
    if (is.list(d$uurl)) d[, uurl := unlist(uurl)] else d
  }
  d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
  d_rbl <- d_data[, rbindlist(DATA, fill = T)]
  d_rbl[nexti == 0L, reviews.nexti := nexti]
  d_rbl <- d_rbl[, !c('nexti','user_links')]
  setnames(d_rbl, str_remove(names(d_rbl), "^reviews\\."))
  d_rbl <- d_rbl[!((str_detect(uurl, "^$") | is.na(uurl)) & nexti != 0)]
  d_rbl <- d_rbl[!is.na(uurl)]
  d_rbl <- d_rbl[!duplicated(d_rbl[, .(surl, uurl)])]
  d_rbl[, surl := str_remove(surl, trim_url_RE)]
  d_rbl[, surl := str_remove(surl, fixed(appd_txt))]
  d_rbl[, surl := str_remove(surl, "/$")]
  # d_rbl[, .(surl, uurl)][, unique(.SD)][, by = 'uurl', .N][order(-N)][1:100]
  d_tos <- copy(d_rbl)
  set(d_tos, j = 'nexti', value = NULL)
  d_tos
}

## Load rev - reviews ####
rev_load <- function(file_list = user_file) {
  d_data <- f_read_lines(file_list)[[1]]
  d_data[, JSON := rep(list(), .N)]
  d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
  f_asDT <- function(l) {
    d <- as.data.table(l)
    if (is.list(d$user_links)) d[, user_links := unlist(user_links)] else d
  }
  d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
  d_data <- d_data[!d_data[, sapply(DATA, nrow) == 1L]]
  d_rbl <- d_data[, rbindlist(DATA, fill = T)]
  setnames(d_rbl, str_remove(names(d_rbl), "^reviews\\."))
  setnames(d_rbl, 'user_link', 'uurl')
  d_rbl <- d_rbl[surl != ""]
  d_rbl <- d_rbl[!duplicated(d_rbl[, .(uurl, surl)])]
  setcolorder(d_rbl, c('surl','uurl'))
  d_rbl
}

## Load cov - converts ####
cov_load <- function(file_list = conversion_file) {
  d_data <- f_read_lines(file_list)[[1]]
  if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
  d_data[, JSON := rep(list(), .N)]
  # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
  d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
  f_asDT <- \(l) {as.data.table(l)}
  d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
  d_cov <- d_data[, rbindlist(DATA, fill = T)]
  d_cov <- d_cov[murl != ""]
  d_cov[, surl := str_remove(surl, "/$")]
  d_cov
}

## Load cov - converts ####
rot_load <- function(file_list = rotten_file) {
  d_data <- f_read_lines(file_list)[[1]]
  if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
  d_data[, JSON := rep(list(), .N)]
  # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
  d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
  f_asDT <- \(l) {as.data.table(l)}
  d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
  d_rot <- d_data[, rbindlist(DATA, fill = T)]
  d_rot <- d_rot[!is.na(title)]
  d_rot <- d_rot[!duplicated(surl)]
  if (TRUE) {
    # c('imdbid', 'title', 'year', 'tomatourl', 'rated', 'released', 
    #   'runtime', 'genre', 'director', 'writer', 'actors', 'plot', 'language', 
    #   'country', 'awards', 'poster', 'metascore', 'imdbrating', 'imdbvotes', 
    #   'tomatorating', 'dvd', 'boxoffice', 'production', 'website', 
    #   'priority')
    
    flds <- c('year','scr_brd')
    d_rot[, (flds) := tsub(scr_brd, str_split_1, pattern = "(?<=^\\d{4}),[ ]*")]
    flds <- c('runtime','scr_brd')
    d_rot[str_detect(scr_brd, "^(\\dh )?\\d{1,2}m"), (flds) := .(scr_brd, NA)]
    flds <- c('genre','scr_brd')
    d_rot[!str_detect(scr_brd, ","), (flds) := .(scr_brd, NA) ]
    flds <- c('genre','runtime')
    d_rot[!is.na(scr_brd), (flds) := tsub(scr_brd, str_split_1, pattern = ",[ ]*")]
    set(d_rot, j = 'scr_brd', value = NULL)
    
    # f_str_split <- function(...) str_split(..., n = 2)[[1]]
    # d_rot[, tsub(scr_brd, f_str_split, pattern = ",[ ]*")]
    
  }
 
  
  d_rot
}

## Load mov - movies ####
mov_load <- function(file_list = movies_Rds, movies_file = NULL) {
  if (!is.null(movies_file)) {
    d_data <- f_read_lines(movies_file)[[1]]
    d_data[, imdbID := str_extract(raw, "(?<=\"imdbID\":\")tt\\d+")]
    d_data[, Response := str_extract(raw, "(?<=\"Response\":\")False")]
    d_data <- d_data[!isTRUE(Response == "False")]
    d_data <- d_data[!duplicated(imdbID, fromLast = T)]
    stopifnot(has.0rows(d_data[has.a_duplicate(imdbID)]))
    
    # grab_source("02g")
    d_data <- d_data[!duplicated(raw)]
    if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
    d_data[, JSON := rep(list(), .N)]
    # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
    d_data[, JSON := pbapply::pblapply(raw, \(x) jsonlite::fromJSON(x))]
    d_skel <- c("Internet Movie Database","Rotten Tomatoes","Metacritic") %>% 
      data.table(Source = .)
    d_skel[, Value := NA_character_]
    f_fixratings <- \(l) {
      if (is.null(nrow(l$Ratings))) {
        l$Ratings <- copy(d_skel)
      }
      if (nrow(l$Ratings) != 3L) {
        browser(expr = is.na(l$Ratings))
        d_s <- copy(d_skel)[as.data.table(l$Ratings), on = 'Source', Value := i.Value]
        l$Ratings <- d_s
      }; l
    }
    d_data[, JSON := pbapply::pblapply(JSON, f_fixratings)]
    d_data[, JSON := pbapply::pblapply(JSON, \(l) as.list(unlist(l)))]
    d_rbl <- d_data[, rbindlist(JSON, fill = T)]
    
    f_fixna <- \(x) {x[str_detect(x, "^N/A$")] <- NA_character_; x}
    for (j in names(d_rbl)) set(d_rbl, j = j, value = f_fixna(d_rbl[[j]]))
    # setf(d_rbl, value = f_fixna)
    
    msg <- "Can't collapse Ratings.Source1"
    stopifnot(has.0rows(d_rbl[str_replace_na(str_extract(Ratings.Value1, 
                                                         "[^/]+(?=/)")) != str_replace_na(imdbRating)]))
    set(d_rbl, j = c('Ratings.Source1','Ratings.Value1'), value = NULL)
    
    msg <- "Can't collapse Ratings.Value3"
    stopifnot(has.0rows(d_rbl[str_replace_na(str_extract(Ratings.Value3, 
                                                         "[^/]+(?=/)")) != str_replace_na(Metascore)]))
    set(d_rbl, j = c('Ratings.Source3','Ratings.Value3'), value = NULL)
    
    d_rbl[is.na(tomatoRating), tomatoRating := Ratings.Value2]
    
    set(d_rbl, j = c('Ratings.Source2','Ratings.Value2'), value = NULL)
    
    setcolorder(d_rbl, c('imdbID','Title','Year','tomatoURL'))
    
    f_rmComma <- \(x) as.integer(str_remove_all(x, "[\\$,%]"))
    fmt_flds <- c('imdbVotes','BoxOffice','tomatoRating')
    for (j in fmt_flds) set(d_rbl, j = j, value = f_rmComma(d_rbl[[j]]))
    d_rbl[, imdbRating := as.numeric(imdbRating)]
    d_rbl <- d_rbl[!is.na(imdbID)]
    
    fp <- "D:/Movie-Database/database/imdbfrozen"
    save3_loc <- file.path(fp, "extract3.Rds")
    d_frz <- readRDS(save3_loc)
    d_frz[, log_nv := log(numVotes)]
    d_frz[, priority := averageRating * log_nv]
    setorder(d_frz, -priority)
    d_frz[, i := .I]
    
    if (TRUE) {
      d_rbl[d_frz, on = c(imdbID = 'tconst'), `:=`(
        dl_imdb_rating = i.averageRating, dl_imdb_nvotes = i.numVotes)]
      d_rbl[is.na(imdbRating) & !is.na(dl_imdb_rating), imdbRating := dl_imdb_rating]
      d_rbl[is.na(imdbVotes) & !is.na(dl_imdb_nvotes), imdbVotes := dl_imdb_nvotes]
      set(d_rbl, j = c('dl_imdb_rating','dl_imdb_nvotes'), value = NULL)
    }
    
    f_det_newline <- \(x) any(str_detect(x, "[\n\r]"), na.rm = T)
    fix_fls <- names(which(d_rbl[, sapply(.SD, f_det_newline)]))
    f_fix_newline <- \(x) str_replace_all(x, "[\n\r]", " ")
    for (j in fix_fls) set(d_rbl, j = j, value = f_fix_newline(d_rbl[[j]]))
    
    f_det_dq <- \(x) any(str_detect(x, "\""), na.rm = T)
    fix_fls <- names(which(d_rbl[, sapply(.SD, f_det_dq)]))
    f_fix_dq <- \(x) str_replace_all(x, "\"", "'")
    for (j in fix_fls) set(d_rbl, j = j, value = f_fix_dq(d_rbl[[j]]))
    
    # d_rbl[d_frz, on = c(imdbID = 'tconst'), priority := i.priority]
    # d_rbl[, log_nv := log(imdbVotes)]
    d_rbl[, priority := imdbRating * log(imdbVotes)]
    d_rbl[is.na(priority), priority := log(imdbVotes)]
    d_rbl[is.na(priority), priority := 0]
    setorder(d_rbl, -priority)
    d_mov <- d_rbl
  } else {
    d_mov <- readRDS(file_list)
    d_mov[, tomatourl := str_remove(tomatourl, "/$")]
    d_mov[, tomatourl := str_remove(tomatourl, trim_url_RE)]
    d_mov
  }
  d_mov
}



