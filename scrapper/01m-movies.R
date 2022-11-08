source(file.path(getwd(), "00l-loaders.R"))

# read_lines
gf = F; sv = F
fp <- "D:/Movie-Database/database/imdbfrozen"
file_v <- list.files(fp, pattern = "tsv$", recursive = T, full.names = T)
rr <- F; sv <- F

save_loc <- file.path(fp, "extract.Rds")
save2_loc <- file.path(fp, "extract2.Rds") ## Old movie table 
save3_loc <- file.path(fp, "extract3.Rds")
if (rr) {
  d_tbl_l <- list()
  # a <- proc.now()
  for (f_lp in file_v) { ## f_lp=file_v[7]  f_lp=file_v[4] f_lp=file_v[1] 
    cat("Processing: ", f_lp,"\n")
    d_lp <- fread(file = f_lp, sep = "\t", quote = "")
    nms_lp <- str_extract(normalizePath(file.path(f_lp, "..")), FILE_NAME_RE)
    nms_lp %<>% str_replace_all("\\.", "_")
    d_tbl_l <- append(d_tbl_l, setNames(list(d_lp), nms_lp))
    rm(list = ls(pattern = "_lp$"))
  }
  # proc.now(a)
  if (FALSE) {
    d_ <- d_tbl_l[['title_basics']]
    d_[str_detect(primaryTitle, "(?i)joker") & startYear == "2019"]
  }
  d_tbl_l[['title_basics']] <- d_tbl_l[['title_basics']][titleType == "movie"]
  d_tbl_l[['title_basics']] <- d_tbl_l[['title_basics']][isAdult == 0L]
  d_tbl_l[['title_basics']] <- d_tbl_l[['title_basics']][!str_detect(genres, "Adult")]
  d_tbl_l[['title_basics']][d_tbl_l[['title_ratings']], on = 'tconst',
    `:=`(averageRating = i.averageRating, numVotes = i.numVotes)]
  d_tbl_l[['title_basics']] <- d_tbl_l[['title_basics']][!is.na(averageRating) & !is.na(numVotes)]
  d_tbl_l[['title_basics']][str_detect(genres, "\\\\N"), genres := NA]
  d_tbl_l[['title_basics']][str_detect(runtimeMinutes, "\\\\N"), runtimeMinutes := NA]
  d_tbl_l[['title_basics']][primaryTitle == originalTitle, originalTitle := NA]
  
  set(d_tbl_l[['title_basics']], j = c('titleType','endYear','isAdult'), value = NULL)
}
if (rr & sv) saveRDS(d_tbl_l, save_loc)
if (!rr & FALSE) {
  d_tbl_l <- readRDS(save_loc)
  d <- copy(d_tbl_l[['title_basics']]); beepr::beep()
}
if (rr & sv) saveRDS(d_tbl_l[['title_basics']], save3_loc)
if (!rr) d <- readRDS(save3_loc)
d_frz <- d; rm(d)
d_frz[, log_nv := log(numVotes)]
d_frz[, priority := averageRating * log_nv]
setorder(d_frz, -priority)
d_frz[, i := .I]

## https://www.dataquest.io/blog/r-api-tutorial/
## https://pypi.org/project/omdb/
# library(httr)
# library(jsonlite)

d_data <- f_read_lines(movies_file)[[1]]
d_data[, imdbID := str_extract(raw, "(?<=\"imdbID\":\")tt\\d+")]
d_data[, Response := str_extract(raw, "(?<=\"Response\":\")False")]
d_data <- d_data[!isTRUE(Response == "False")]
d_data <- d_data[!duplicated(imdbID, fromLast = T)]
d_data[, Runtime := str_extract(raw, "(?<=\"Runtime\":\")[A-Za-z0-9 /,.]+(?=\",)")]
d_data <- d_data[!str_detect(Runtime, "[Ss]")]

# d_data[, Runtime %>% unique()]
stopifnot(has.0rows(d_data[has.a_duplicate(imdbID)]))
d_frz[d_data, on = c(tconst = 'imdbID'), completed := i]
d_remains <- d_frz[is.na(completed)]


## Elapsed time

# pb <- progress_bar$new(
#   format = "RT: :elapsedfull | Tick: :current | TpS: :tick_rate | %done::percent | Eta: :eta | :title (:year)",
#   total = nrow(d_remains), clear = FALSE); pb$tick()
if (F) imdbID_lp <- "tt0317705"

for (i in seq(nrow(d_remains))) {  #i=1  #i=1977
  # pb$tick(tokens = list(title = d_remains[i, primaryTitle], year = d_remains[i, startYear]))
  imdbID_lp <- d_remains[i, tconst]
  a_lp <- proc.time()
  res_to_lp <- tryCatch({
    res_lp = httr::GET(paste0(api_link, imdbID_lp), httr::timeout(60 * 5)) #, httr::timeout(120)
  }, error = function(e) e)
  a_lp <- round((proc.time() - a_lp)[['elapsed']]/60, 2)
  cat("[", a_lp, " mins]")
  if (!is.null(res_to_lp$message)) {
    cat("  timeout: ", res_to_lp$message, "\n")
    next
  } else {
    cat("\n")
  }
  if (res_lp$status_code != 200) {
    cat("Status: ", res_lp$status_code, " detected. continue loop. i =", i, "\n")
    next
  }
  data_lp = rawToChar(res_lp$content)
  if (str_detect(data_lp, "(?<=\"Error\":\")(Incorrect IMDb ID|Error getting data)")) {
    data_lp <- str_replace(data_lp, "\\}", paste0(',"imdbID":"', imdbID_lp, '"}'))
  }
  cat(data_lp, sep = "\n", file = movies_file, append = TRUE)
  rm(list = ls(pattern = "_lp$"))
  Sys.sleep(0.1)
}
# pb$terminate()
beepr::beep()

## Clean ####
if (FALSE) {
  # d_mov[str_detect(runtime, "(?i)s")]
  # res_lp = httr::GET(paste0(api_link, "tt4633694"), httr::timeout(60 * 5))
  # data_lp = rawToChar(res_lp$content)
  
  
  # # grab_source("02g")
  # d_data <- d_data[!duplicated(raw)]
  # if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
  # d_data[, JSON := rep(list(), .N)]
  # # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
  # d_data[, JSON := pbapply::pblapply(raw, \(x) jsonlite::fromJSON(x))]
  # d_skel <- c("Internet Movie Database","Rotten Tomatoes","Metacritic") %>% 
  #   data.table(Source = .)
  # d_skel[, Value := NA_character_]
  # f_fixratings <- \(l) {
  #   if (is.null(nrow(l$Ratings))) {
  #     l$Ratings <- copy(d_skel)
  #   }
  #   if (nrow(l$Ratings) != 3L) {
  #     browser(expr = is.na(l$Ratings))
  #     d_s <- copy(d_skel)[as.data.table(l$Ratings), on = 'Source', Value := i.Value]
  #     l$Ratings <- d_s
  #   }; l
  # }
  # d_data[, JSON := pbapply::pblapply(JSON, f_fixratings)]
  # d_data[, JSON := pbapply::pblapply(JSON, \(l) as.list(unlist(l)))]
  # d_rbl <- d_data[, rbindlist(JSON, fill = T)]
  # 
  # f_fixna <- \(x) {x[str_detect(x, "^N/A$")] <- NA_character_; x}
  # for (j in names(d_rbl)) set(d_rbl, j = j, value = f_fixna(d_rbl[[j]]))
  # # setf(d_rbl, value = f_fixna)
  # 
  # msg <- "Can't collapse Ratings.Source1"
  # stopifnot(has.0rows(d_rbl[str_replace_na(str_extract(Ratings.Value1, 
  #      "[^/]+(?=/)")) != str_replace_na(imdbRating)]))
  # set(d_rbl, j = c('Ratings.Source1','Ratings.Value1'), value = NULL)
  # 
  # msg <- "Can't collapse Ratings.Value3"
  # stopifnot(has.0rows(d_rbl[str_replace_na(str_extract(Ratings.Value3, 
  #     "[^/]+(?=/)")) != str_replace_na(Metascore)]))
  # set(d_rbl, j = c('Ratings.Source3','Ratings.Value3'), value = NULL)
  # 
  # d_rbl[is.na(tomatoRating), tomatoRating := Ratings.Value2]
  # 
  # set(d_rbl, j = c('Ratings.Source2','Ratings.Value2'), value = NULL)
  # 
  # setcolorder(d_rbl, c('imdbID','Title','Year','tomatoURL'))
  # 
  # f_rmComma <- \(x) as.integer(str_remove_all(x, "[\\$,%]"))
  # fmt_flds <- c('imdbVotes','BoxOffice','tomatoRating')
  # for (j in fmt_flds) set(d_rbl, j = j, value = f_rmComma(d_rbl[[j]]))
  # d_rbl[, imdbRating := as.numeric(imdbRating)]
  # d_rbl <- d_rbl[!is.na(imdbID)]
  # 
  # if (TRUE) {
  #   d_rbl[d_frz, on = c(imdbID = 'tconst'), `:=`(
  #     dl_imdb_rating = i.averageRating, dl_imdb_nvotes = i.numVotes)]
  #   d_rbl[is.na(imdbRating) & !is.na(dl_imdb_rating), imdbRating := dl_imdb_rating]
  #   d_rbl[is.na(imdbVotes) & !is.na(dl_imdb_nvotes), imdbVotes := dl_imdb_nvotes]
  #   set(d_rbl, j = c('dl_imdb_rating','dl_imdb_nvotes'), value = NULL)
  # }
  # 
  # f_det_newline <- \(x) any(str_detect(x, "[\n\r]"), na.rm = T)
  # fix_fls <- names(which(d_rbl[, sapply(.SD, f_det_newline)]))
  # f_fix_newline <- \(x) str_replace_all(x, "[\n\r]", " ")
  # for (j in fix_fls) set(d_rbl, j = j, value = f_fix_newline(d_rbl[[j]]))
  # 
  # f_det_dq <- \(x) any(str_detect(x, "\""), na.rm = T)
  # fix_fls <- names(which(d_rbl[, sapply(.SD, f_det_dq)]))
  # f_fix_dq <- \(x) str_replace_all(x, "\"", "'")
  # for (j in fix_fls) set(d_rbl, j = j, value = f_fix_dq(d_rbl[[j]]))
  # 
  # # d_rbl[d_frz, on = c(imdbID = 'tconst'), priority := i.priority]
  # # d_rbl[, log_nv := log(imdbVotes)]
  # d_rbl[, priority := imdbRating * log(imdbVotes)]
  # d_rbl[is.na(priority), priority := log(imdbVotes)]
  # d_rbl[is.na(priority), priority := 0]
  # setorder(d_rbl, -priority)
  # d_mov <- d_rbl
  
  d_mov <- mov_load(movies_file = movies_file)
  d_mov_save <- d_mov[!is.na(tomatoURL)]
  
  # hovertext_flds <- c('Title','imdbRating','BoxOffice','imdbVotes','tomatoRating')
  # dp[, txt := apply(.SD, 1, p0v, collapse = "\n"), .SDc = hovertext_flds]
  if (sv) {
    # grab_source("06t")
    setnames(d_mov_save, str_to_lower(names(d_mov_save)))
    rm_flds <- names(which(d_mov_save[, sapply(.SD, \(x) uniqueN(x) == 1)]))
    rm_flds %<>% c('response', 'error','type') %>% unique # 'priority',
    rm_flds <- intersect(rm_flds, names(d_mov_save))
    set(d_mov_save, j = rm_flds, value = NULL)
    f_str_IDate <- \(x) as.IDate(strptime(x, format = "%d %b %y", tz = "UTC"))
    fmt_flds <- c('released','dvd')
    for (j in fmt_flds) set(d_mov_save, j = j, value = f_str_IDate(d_mov_save[[j]]))
    
    # setf(d_mov_save, j = fmt_flds, value = f_str_IDate)
    if ('totalseasons' %in% names(d_mov_save)) {
      d_mov_save <- d_mov_save[is.na(totalseasons)]
    }
    rm_flds <- c('totalseasons','season','episode','seriesid')
    rm_flds <- intersect(rm_flds, names(d_mov_save))
    set(d_mov_save, j = rm_flds, value = NULL)
    
    if (TRUE) {
      saveRDS(d_mov_save, movies_Rds)
    }
    
    if (TRUE) {
      d_dbase <- copy(d_mov_save)
      if (!exists('d_tos')) d_tos <- tos_load()
      if (!exists('d_rev')) d_rev <- rev_load()
      if (!exists('d_cov')) d_cov <- cov_load()
      
      d_surl <- rbind(
        d_tos[, 'surl'],
        d_rev[, 'surl'],
        melt(copy(d_cov)[, i := .I], id.vars = 'i', value.name = 'surl')[, 'surl']
      )[, unique(.SD)]
      
      d_dbase[, surl := tomatourl]
      d_dbase[, surl := str_remove(surl, trim_url_RE)]
      d_dbase[, surl := str_remove(surl, "/$")]
      d_dbase <- d_dbase[d_surl, on = 'surl', nomatch = 0][, !'surl']
      
      setcolorder(d_dbase, c('tomatourl'))
      d_dbase[, tomatourl := str_remove(tomatourl, trim_url_RE)]
      d_dbase[, tomatourl := str_remove(tomatourl, "^/m/")]
      d_dbase[, tomatourl := str_remove(tomatourl, "/$")]
      
      if (!has.0rows(d_dbase[has.a_duplicate(tomatourl)])) {
        d_dbase[, dp_dx := duplicate_index(.SD), .SDc = c('tomatourl')]
        pick_dup <- \(SD) {
          if (is.na(get('.BY', envir = parent.frame()))) return(SD)
          # browser()
          return(SD[which.max(priority)])
        #   if (nrow(SD) == 2L) {
        #     if (max(SD$priority) - min(SD$priority) > 20) {
        #       return(SD[which.max(priority)])
        #     }
        #   }
        #   browser()
        }
        d_dbase <- d_dbase[, by = 'dp_dx', pick_dup(.SD)]
        d_dbase[, dp_dx := NULL]
        
        setorder(d_dbase, -priority)
        # d_dbase[, substr(tomatourl, 1,1)] %>% unique
        # d_dbase[str_detect(tomatourl, "^[\\$]")]
        # "https://www.rottentomatoes.com/m/$5_a_day"
        # "https://www.rottentomatoes.com/m/no_time_to_die_2021"
        # "https://www.rottentomatoes.com/m/bond_25"
        # d_dbase[str_detect(title, "(?i)No.Time.to.(Die|Cry)")]
      }
      d_dbase[, runtime := str_remove(runtime, "[Ss]")]
      
      
      ## https://www.w3schools.com/sql/ ##
      con <- odbc::dbConnect(odbc::odbc(), "PostgreSQL35Wtest")
      
      if (!exists('v')) v <- T
      if (v) RPostgreSQL::dbGetQuery(chkc(con), "select TRUE;")
      if (v) RPostgreSQL::dbGetQuery(chkc(con), "SELECT COUNT(*) FROM movies")
      # if (v) vector_venn(d_dbase %>% names, RPostgreSQL::dbListFields(con, 'movies'))
      if (setequal(d_dbase %>% names, RPostgreSQL::dbListFields(con, 'movies'))) {
        RPostgreSQL::dbWriteTable(chkc(con), 'movies', overwrite = TRUE, d_dbase)
        qry_ <- "ALTER TABLE movies ADD PRIMARY KEY (tomatourl);"
        RPostgreSQL::dbGetQuery(chkc(con), qry_)
      }
    }
  }
}

if (FALSE) {
  
  qry_ <- "
      SELECT * 
      FROM movies 
      ORDER BY imdbid desc
      LIMIT 10
      "
  RPostgreSQL::dbGetQuery(chkc(con), qry_) %>% sapply(typeof)
  RPostgreSQL::dbGetQuery(chkc(con), qry_) %>% as.data.table
  
  qry_ <- "
      ALTER TABLE movies
      ALTER COLUMN imdbrating TYPE real;
      "
  RPostgreSQL::dbGetQuery(chkc(con), qry_)
  
  
  qry_ <- "
      SELECT pg_typeof(imdbid)
      FROM movies
      LIMIT 1;
      "
  qry_ <- "
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'movies';
      "
  # RPostgreSQL::dbListFields(chkc(con), 'movies') 
  
  RPostgreSQL::dbGetQuery(chkc(con), qry_)
  
  
  
  ## https://www.postgresql.org/docs/current/datatype.html
  
  DBI::dbCanConnect(chkc(con))
  
  RPostgreSQL::dbColumnInfo()
  
  
  
  
  RPostgreSQL::dbCommit()
  RPostgreSQL::dbDataType(chkc(con), 'data.frame')
  RPostgreSQL::dbListFields(chkc(con), 'movies')
  RPostgreSQL::dbWriteTable(chkc(con), 'movies', overwrite = TRUE, d_rbl)
  
  
  library('sqldf')
  sqldf::sqldf(connection = con, "")
  
  
  
  
  fp <- "C:/Users/rbruner/Desktop/movie-dump.csv"
  fwrite(d_rbl, fp)
  
  
  d_rbl[, sapply(.SD, af(x, max(nchar(x), na.rm = T)))]
  d_rbl[str_detect(plot, "film starts with previous massacres and represions")]
  
  "
  CREATE TABLE movies (
  imdbid VARCHAR(10),
  title VARCHAR(250),
  year VARCHAR(10),
  tomatourl VARCHAR(150),
  rated VARCHAR(15),
  released VARCHAR(11),
  runtime VARCHAR(10),
  genre VARCHAR(65),
  director VARCHAR(375),
  writer VARCHAR(700),
  actors VARCHAR(150),
  plot VARCHAR(3000),
  language VARCHAR(500),
  country VARCHAR(250),
  awards VARCHAR(70),
  poster VARCHAR(150),
  metascore VARCHAR(3),
  imdbrating VARCHAR(3),
  imdbvotes VARCHAR(8),
  type VARCHAR(8),
  tomatorating VARCHAR(3),
  dvd VARCHAR(12),
  boxoffice VARCHAR(10),
  production VARCHAR(300),
  website VARCHAR(100),
  PRIMARY KEY (imdbid)
  )
  
COPY movies(
	imdbid, 
	title, 
	year, 
	tomatourl, 
	rated, 
	released, 
	runtime, 
	genre, 
	director, 
	writer
	actors,
	plot,
  language,
  country,
  awards,
  poster,
  metascore,
  imdbrating,
  imdbvotes,
  type,
  tomatorating,
  dvd,
  boxoffice,
  production,
  website
)
FROM 'C:\Users\rbruner\Desktop\movie-dump.csv'
DELIMITER ','
CSV HEADER;
  "

}

if (FALSE) {
  
  if (gf) {
    dp <- copy(d_rbl)[!is.na(imdbRating) & !is.na(BoxOffice) & !is.na(imdbVotes)]
    # dp <- dp[1:100]
    dp[, I := .I]
    dp[, BoxOffice_log := log(BoxOffice)]
    dp[, imdbVotes_log := log(imdbVotes)]
    
    hovertext_flds <- c('Title','imdbRating','BoxOffice','imdbVotes')
    dp[, txt := apply(.SD, 1, p0v, collapse = "\n"), .SDc = hovertext_flds]
    library('ggplot2')
    library('plotly')
    # + scale_x_log10()  
  }
  if (gf) {
    ggplot(dp) +
      geom_point(
        aes(x = I,
            y = imdbRating,
            fill = BoxOffice_log,
            color = BoxOffice_log)
      ) + theme_dark()
  }
  if (gf) {
    p <- ggplot(
      dp, 
      aes(x = imdbRating, 
          y = imdbVotes_log, 
          fill = BoxOffice_log, 
          color = BoxOffice_log)) +
      geom_point(aes(text = txt)) + 
      geom_jitter(width = 0.4) + theme_dark()
    ggplotly(p, tooltip = 'txt')
  }
  # d_rbl[, .N, by = .(is.na(tomatoRating))]
  if (gf) {
    dp <- copy(d_rbl)[
      !is.na(imdbRating) & 
        !is.na(BoxOffice) & 
        !is.na(imdbVotes) & 
        !is.na(tomatoRating)]
    
    # dp <- dp[1:100]
    dp[, I := .I]
    dp[, BoxOffice_log := log(BoxOffice)]
    dp[, imdbVotes_log := log(imdbVotes)]
    
    hovertext_flds <- c('Title','imdbRating','BoxOffice','imdbVotes','tomatoRating')
    dp[, txt := apply(.SD, 1, p0v, collapse = "\n"), .SDc = hovertext_flds]
  }
  if (gf) {
    p <- ggplot(
      dp, 
      aes(x = tomatoRating, 
          y = imdbVotes_log, 
          fill = BoxOffice_log, 
          color = BoxOffice_log)) +
      geom_point(aes(text = txt)) + 
      geom_jitter(width = 0.4) + theme_dark()
    ggplotly(p, tooltip = 'txt')
  }
  if (gf) {
    p <- ggplot(
      dp, 
      aes(x = imdbRating, 
          y = tomatoRating, 
          # fill = imdbVotes_log, 
          # color = imdbVotes_log
          fill = BoxOffice_log, 
          color = BoxOffice_log
      )) +
      geom_point(aes(text = txt)) + 
      geom_jitter(width = 0.4) + theme_dark()
    ggplotly(p, tooltip = 'txt')
  }
  if (gf) {
    ggplot(dp[, 'tomatoRating']) + geom_histogram(aes(x = tomatoRating), binwidth = 1)
    ggplot(dp[, 'imdbRating']) + geom_histogram(aes(x = imdbRating), binwidth = .1)
  }
  
}
# res_to_lp <- tryCatch({
#   res_lp = httr::GET(paste0(api_link, imdbID_lp), httr::timeout(.00001))
# }, error = function(e) e)


# data = jsonlite::fromJSON(rawToChar(res$content))



# [str_detect(primaryTitle, "(?i)fight club")]
# titleType_ <- c("movie")



# search_tables(tables = d_tbl_l, pattern = "tt0137523")

## https://rapidapi.com/collection/rotten-tomatoes-api

## regext JSON play ####
if (FALSE) {
  x <- d_data[1, raw]
  "{\"Title\":\"The Shawshank Redemption\",\"Year\":\"1994\",\"Rated\":\"R\",\"Released\":\"14 Oct 1994\",\"Runtime\":\"142 min\",\"Genre\":\"Drama\",\"Director\":\"Frank Darabont\",\"Writer\":\"Stephen King, Frank Darabont\",\"Actors\":\"Tim Robbins, Morgan Freeman, Bob Gunton\",\"Plot\":\"Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.\",\"Language\":\"English\",\"Country\":\"United States\",\"Awards\":\"Nominated for 7 Oscars. 21 wins & 43 nominations total\",\"Poster\":\"https://m.media-amazon.com/images/M/MV5BMDFkYTc0MGEtZmNhMC00ZDIzLWFmNTEtODM1ZmRlYWMwMWFmXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_SX300.jpg\",\"Ratings\":[{\"Source\":\"Internet Movie Database\",\"Value\":\"9.3/10\"},{\"Source\":\"Rotten Tomatoes\",\"Value\":\"91%\"},{\"Source\":\"Metacritic\",\"Value\":\"81/100\"}],\"Metascore\":\"81\",\"imdbRating\":\"9.3\",\"imdbVotes\":\"2,640,847\",\"imdbID\":\"tt0111161\",\"Type\":\"movie\",\"tomatoMeter\":\"N/A\",\"tomatoImage\":\"N/A\",\"tomatoRating\":\"N/A\",\"tomatoReviews\":\"N/A\",\"tomatoFresh\":\"N/A\",\"tomatoRotten\":\"N/A\",\"tomatoConsensus\":\"N/A\",\"tomatoUserMeter\":\"N/A\",\"tomatoUserRating\":\"N/A\",\"tomatoUserReviews\":\"N/A\",\"tomatoURL\":\"https://www.rottentomatoes.com/m/shawshank_redemption/\",\"DVD\":\"21 Dec 1999\",\"BoxOffice\":\"$28,767,189\",\"Production\":\"N/A\",\"Website\":\"N/A\",\"Response\":\"True\"}"
  headers <- str_extract_all(d_data[1, raw], "(?<=(,|\\{)\")[^\"]+(?=\":)")[[1]]
  content <- str_extract_all(d_data[1, raw], "(?<=:\")[^\"]+(?=\",\")")
  
  RE <- sprintf("(?<%s>%s)", headers[1:2],  "(?<=:\")[^\"]+(?=\",\")")
  RE <- "(?<title>(?<=:\")[^\"]+(?=\",\"))[^\"]+(?<year>(?<=:\")[^\"]+(?=\",\"))"
  # p0("\\b", p00(RE))
  
  stringr::str_match(x, RE)
  
  x <- rep("https://mail.google.com/mail/u/0/?shva=1#inbox", 3)
  RE <- "\\b(?<protocol>https?|ftp)://(?<domain>[-A-Za-z0-9.]+)(?<file>/[-A-Za-z0-9+&@#/%=~_|!:,.;]*)?(?<parameters>\\?[A-Za-z0-9+&@#/%=~_|!:,.;]*)?"
  
  
  str_match(x, "(?<=,\")[^\"]+(?=\":)")
  
  
  stringr::str_match_all(x, RE)
  
  d_data[1:3]
}

## video sucks ####
if (FALSE) {
  SD_ <- c('primaryTitle', 'tconst')
  d_ss <- d_tbl_l[['title_basics']][titleType == "video", .SD, .SDc = SD_]
  d_tbl_l[['title_ratings']][d_ss, on = 'tconst'][numVotes > 1000][order(-averageRating)][1:300] %P% P
}

## Old Code ####

if (FALSE) {
  d_data[str_detect(raw, "(?i)\"Error\"")]
  d[d_data[!duplicated(imdbID)], on = c(tconst = 'imdbID'), 
    api_imdb_rating := imdbID]
  
}

if (FALSE) {
  if (F) {
    data = d[is.na(completed)]
    fld = 'i'
    seq_n = 5
  }
  f_isseq <- function(data, fld, seq_n = 5) {
    if (!is.data.table(data) & is.vector(data)) {
      data <- as.data.table(list(i = data)); fld <- 'i'
    }
    d_ <- copy(data)[, .(
      shift(get(fld), n = 0, fill = 0L, type = 'lead') - 0L,
      shift(get(fld), n = 1, fill = 0L, type = 'lead') - 1L,
      shift(get(fld), n = 2, fill = 0L, type = 'lead') - 2L,
      shift(get(fld), n = 3, fill = 0L, type = 'lead') - 3L,
      shift(get(fld), n = 4, fill = 0L, type = 'lead') - 4L
    )
    ]
    d_[, seq := apply(.SD, 1, function(x) uniqueN(x) == 1L)]
    chk_fld <- paste0("V", max(str_extract(names(d_), "\\d+"), na.rm = T))
    # d_ %>% tail(20)
    d_[get(chk_fld) < 1, seq := TRUE]
    d_$seq
  }
  
  d[!(completed) | is.na(completed), no_error := f_isseq(i)]
  
  d_remains <- d[is.na(completed) & (no_error)]
} else {
  
}
