source(file.path(getwd(), "00l-loaders.R"))
v <- F
method1 <- FALSE
parallel_run <- FALSE
mod_ <- ifelse(Sys.getenv('COMPUTERNAME') == "HS-WS-DS2", "a", "b")
tomato2_files
tomato2_file <- if (Sys.getenv('COMPUTERNAME') == "HS-WS-DS2") {
  file.path(sav_loc, "tomatos2a.txt")
} else {
  file.path(sav_loc, "tomatos2b.txt")
  file.path(sav_loc, "tomatos2c.txt")
}

# d <- readRDS(file = normalizePath(movies_Rds))
# d <- d[!is.na(tomatourl)]
# d <- d[imdbvotes > 200]
# d <- d[str_detect(language, "(?i)english")]
# d[!str_detect(tomatourl, "/$"), tomatourl := paste0(tomatourl, "/")]
# d <- d[, 'tomatourl']
d_mov <- mov_load()

# trim_url_RE <- "https?://(www\\.)?rottentomatoes.com"
# appd_txt <- "reviews?type=user"
# d[, tomatourl := str_remove(tomatourl, trim_url_RE)]
if (!parallel_run) d_mov[, mod := fifelse(.I %% 2 != 0L, "a", "b")]

tom_fl <- list.files(sav_loc, pattern = "^tomatos2.*.txt$", full.names = T)
# d_tos <- tos_load(str_subset(tom_fl, "2c"))
d_tos <- tos_load(tomato2_file)

if (v) {
  cat("Number of unique user links:", d_tos[, uniqueN(uurl)])
  cat("\n\nTop 25 active users: ")
  d_Nusers <- d_tos[, by = 'uurl', .N][order(-N)]
  cat(paste(d_Nusers[1:25, N], collapse = ","))
  cat("\n\nUsers with 30+ reviews:", nrow(d_Nusers[N >= 30]))
  cat("\n\nStem plot of user activity: ")
  stem(d_tos[, by = 'uurl', .N][order(-N)][, N])
  comp_mov <- nrow(d_mov[d_tos[, unique(surl)], on = 'tomatourl'])
  cat("Completed movies:", comp_mov)
  cat("\n\nTotal Movies:", nrow(d_mov))
  cat("\n\nPercent Completed:", round(comp_mov / nrow(d_mov) * 100, 2), "%")
}

if (exists('d_tos')) {
  d_remains <- d_mov[!d_tos[, unique(surl)], on = 'tomatourl']
}

if (parallel_run) d_remains[, mod := fifelse(.I %% 2 != 0L, "a", "b")]
if (!parallel_run) d_remains[, mod := mod_]
d_remains <- d_remains[mod == mod_, !'mod']

## https://www.r-bloggers.com/2021/05/r-selenium/
## https://github.com/mozilla/geckodriver/releases/download/v0.31.0/geckodriver-v0.31.0-win64.zip
## Extract gecho
## https://selenium-release.storage.googleapis.com/4.0/selenium-server-standalone-4.0.0-alpha-2.jar
## Put sel server in gecho folder
## Turn on from terminal ##
"C:\\Users\\rbruner\\Desktop\\selenium-server-standalone-4.0.0-alpha-2"
"java -jar selenium-server-standalone-4.0.0-alpha-2.jar"

if (!exists('remDr') || !remDr$getStatus()$ready) {
  remDr <- remoteDriver(
    remoteServerAddr = "localhost",
    # port = free_port(), ## 4444L,
    port = 4444L,
    browserName = "firefox"
  )
  remDr$open()
}


if (F) {
  surl <- d[1, tomatourl] #nrow(d) - 10000
  surl <- d[10000:10005, tomatourl] #nrow(d) - 10000
  surl <- d[i, tomatourl] #nrow(d) - 10000
  # surl <- d[i, tomatourl]
  # surl <- "/m/forgotten_city/"
  # surl <- "/m/hercules-prisoner-of-evil/"
  # surl <- "/m/infinitum_subject_unknown/"
  surl <- "/m/karthikeya_2/"
  surl <- "/m/city_of_god"
  
  
  data_file <- tomato2_file
  rd <- remDr
  nlimit = 50
  sv = F; v = T
  # debugonce(getMovieUserReviewsList); debugonce(.f_extract_tomato_xml)
  getMovieUserReviewsList(remDr, surl, tomato2_file, sv = F, v = T)
}
getMovieUserReviewsList <- function(rd, surl, data_file, sv = TRUE, 
                             nlimit = 50, v = FALSE) {
  trim_txt <- "https://www.rottentomatoes.com"
  appd_txt <- "reviews?type=user"
  nav_url <- paste0(trim_txt, surl, "/", appd_txt)
  err <- tryCatch({
    rd$navigate(nav_url)
  }, error = function(e) e)
  
  if (inherits(err, "error")) { #$message
    l_lp <- list(surl = surl, nexti = 0, user_links = "")
    if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
    return(list(surl = surl, nexti = 0))
  }
  if (exists('err',inherits = F)) rm(list = 'err', inherits = F)
  
  # xp_users <- '//*[@class="audience-reviews__name"]'
  nexti <- 0L
  sleep_time <- 0
  source_err_cnt <- 0
  last_loop <- data.table(uurl = "")
  d_r_hold <- data.table(uurl = character(), rating = integer(), nexti = integer())
  repeat { # browser()
    nexti <- nexti + 1L
    if (v) cat("nexti:", nexti, "| sleep_time:", sleep_time)
    
    pg_src <- NULL
    ##TODO: Fix surl<-"/m/infinitum_subject_unknown/" page 2 ###
    # try(d_r_lp <- f_extract_vector_tomato_xml(pg_xml, surl, nexti), silent = T)
    err <- tryCatch({
      pg_src <- rd$getPageSource()[[1L]]
    }, error = function(e) e)
    if (inherits(err, "error")) { #$message
      if (v) cat("getPageSource>error")
      nexti <- nexti - 1L
      source_err_cnt <- source_err_cnt + 1L
      if (source_err_cnt <= 3L) {
        if (v) cat(" | source_err_cnt<=3 next\n")
        Sys.sleep(sleep_time)
        next
      } else {
        if (v) cat(" | source_err_cnt>3 break\n")
        break
      }
    } else {
      source_err_cnt <- 0L
    }
    
    pg_xml <- xml2::read_html(pg_src)
    
    no_aud_xp <- "//p[@class='center']"
    no_aud_RE <- "No[ ]+Audience[ ]+Reviews"
    no_aud_txt <- xml2::xml_text(xml2::xml_find_first(pg_xml, no_aud_xp))
    if (!is.na(no_aud_txt) &&  str_detect(no_aud_txt, no_aud_RE)) {
      d_blk <- as.data.table(list(uurl = "", rating = 0, nexti = nexti))
      d_r_hold <- rbind(d_r_hold, d_blk)
      if (v) cat(" | no-aud break\n")
      break
    }
    
    no_aud_xp <- "//p[@class='center']"
    no_aud_RE <- "No[ ]+Audience[ ]+Reviews"
    no_aud_txt <- xml2::xml_text(xml2::xml_find_first(pg_xml, no_aud_xp))
    if (!is.na(no_aud_txt) && str_detect(no_aud_txt, no_aud_RE)) {
      d_blk <- as.data.table(list(uurl = "", rating = 0, nexti = nexti))
      d_r_hold <- rbind(d_r_hold, d_blk)
      if (v) cat(" | no-aud break\n")
      break
    }
    
    not_fnd_xp <- "//div[@id='main-page-content']"
    not_fnd_RE <- "404 - Not Found"
    not_fnd_txt <- NA
    try(not_fnd_txt <- xml2::xml_text(xml2::xml_child(
      xml2::xml_find_first(pg_xml, not_fnd_xp))), silent = T)
    if (!is.na(not_fnd_txt) && str_detect(not_fnd_txt, not_fnd_RE)) {
      d_blk <- as.data.table(list(uurl = "", rating = 0, nexti = nexti))
      d_r_hold <- rbind(d_r_hold, d_blk)
      if (v) cat(" | not_fnd break\n")
      break
    }
    
    d_r_lp <- NULL
    ##TODO: Fix surl<-"/m/infinitum_subject_unknown/" page 2 ###
    # try(d_r_lp <- f_extract_vector_tomato_xml(pg_xml, surl, nexti), silent = T)
    if (is.null(d_r_lp)) {
      try(d_r_lp <- f_extract_tomato_xml(pg_xml, surl, nexti), silent = T)
    }
    
    xp_next <- '//*[contains(@class, "js-prev-next-paging-next")]'
    err <- tryCatch({
      nbtn <- rd$findElement(using = "xpath", xp_next)
    }, error = function(e) e)
    if (inherits(err, "error")) { #$message
      l_lp <- list(surl = surl, nexti = 0, user_links = "")
      if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
      return(list(surl = surl, nexti = 0))
    }
    if (exists('err', inherits = F)) rm(list = 'err', inherits = F)
    
    if (nexti >= nlimit) {
      if (v) cat(" | nexti>=nlimit break\n")
      break
    }
    
    if (is.null(d_r_lp)) {
      if (v) cat(" | is.null>d_r_lp next\n")
      sleep_time <- sleep_time + 0.1
      nexti <- nexti - 1L
      Sys.sleep(sleep_time)
      next
    } else {
      a1 <- str_replace_na(d_r_lp$uurl)
      a2 <- str_replace_na(last_loop$uurl)
      if (length(a1) == length(a2) && all(a1 == a2)) {
        if (v) cat(" | last_loop==this_loop next\n")
        sleep_time <- sleep_time + 0.1
        nexti <- nexti - 1L
        Sys.sleep(sleep_time)
        
        err <- tryCatch({
          nbtn$clickElement()
        }, error = function(e) e)
        
        if (inherits(err, "error")) { #$message
          if (v) cat(" | Broken-Click break\n")
          break
        } else {
          next
        }
        
      }
      if (v) cat(" | rbind-nrows:", nrow(d_r_lp))
      d_r_hold <- rbind(d_r_hold, d_r_lp)
    }
    last_loop <- copy(d_r_lp)
    
    
    class_txt <- nbtn$getElementAttribute('class')[[1]]
    # cat("\n", class_txt, "\n")
    # browser()
    if (str_detect(class_txt, "hide")) {
      if (v) cat(" | class_txt>hide break\n")
      break
    }
    
    err <- tryCatch({
      nbtn$clickElement()
    }, error = function(e) e)
    
    if (inherits(err, "error")) { #$message
      if (v) cat(" | Broken-Click break\n")
      break
    }
    
    if (v) cat("\n")
    rm(list = ls(pattern = "_lp$"))
    Sys.sleep(sleep_time)
  }
  
  # up_lp <- str_remove(up_lp, trim_txt)
  l_lp <- list(surl = surl, reviews = d_r_hold)
  if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
  if (v) cat("\n")
  return(list(surl = surl, nexti = nexti))
}

for (i in seq(nrow(d_remains))) {  #  i=1 i=30
  cat("tomatourl: ", d_remains[i, tomatourl], "\n")
  # getMovieUserReviewsList(remDr, d[i, tomatourl], tomato2_file, v = v)
  getMovieUserReviewsList(
    rd = remDr, 
    surl = d_remains[i, tomatourl], 
    data_file = tomato2_file, 
    nlimit = 300, sv = T, v = T)
}

