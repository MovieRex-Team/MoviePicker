## 02l junk ####



## Old Code ####
if (FALSE) {
  req <- httr::GET("https://www.rottentomatoes.com/m/godfather/") #, config(token = token)
  req$url
  cont <- httr::content(req, as = "parsed")
  redirect_url_xp <- 
    xml2::xml_find_first(cont, )
  
  cont <- httr::content(req, as = "text")
  str_locate_all(cont, "(?<!the_)godfather")
  det_sdx <- str_locate_all(cont, "https?://www.rottentomatoes.com/m/the_godfather")[[1]]
  substring(cont, det_sdx[, 1] - 60, det_sdx[, 2] + 30)
  
  substring(cont, 1, 1000)
  cat()
  
  req <- httr::GET(url, google_token()) %>%
    httr::stop_for_status()
  
  #' Write the JSON to file so we can stick it in this gist.
  req %>%
    httr::content(as = "text") %>%
    jsonlite::prettify() %>%
    cat(file = "drive_user.json")
}


if (FALSE) {
  if (FALSE) {
    joined_imdbid <- d_comb[!is.na(imdbid), !c('uurl','rating')][, unique(.SD)]
    d[J(joined_imdbid), on = 'imdbid', surl := i.surl]
  } else {
    d_rev[str_detect(surl, "/$", negate = T), surl := p0(surl, "/")]
    d_surl <-  d_rev[!is.na(tomatourl), !c('uurl','rating')][, unique(.SD)]
    d_surl[, fix := FALSE]
    d[d_surl, on = c(tomatourl = 'surl'), fix := i.fix]
    d[is.na(fix), fix := TRUE]
  }
  # d[, .N, by = fix]
  # 
  # # d[(fix), by = 'tomatourl', murl := link_conversion(remDr, tomatourl, conversion_fle, sv = FALSE)]
  # 
  # d_fix <- d[(fix)]
  # for (i in seq(nrow(d_fix))) {  # i =1
  #   d_lp <- d_fix[i]
  #   res_lp <- link_conversion(remDr, d_lp$tomatourl, conversion_file, sv = T)
  #   msg_lp <- sprintf("'%s' (%s): '%s' to '%s'\n", 
  #                     d_lp$title, d_lp$year, res_lp$surl, res_lp$murl)
  #   cat(msg_lp)
  #   rm(list = ls(pattern = "_lp$"))
  # }
  
  
  # d[()]
  # d[(fix)]
  
  # d[str_detect(tomatourl, "(?i)star_wars")][1][, by = 'tomatourl', murl := link_conversion(remDr, tomatourl)$murl][]
  
  # d_rev[str_detect(surl, "(?i)star_wars"), !c('uurl','rating')][, unique(.SD)]
  
  
  
  
  d_comb[str_detect(surl, "(?i)a.new.hope"), !c('uurl','rating')][, unique(.SD)]
  
  
  d[str_detect(title, "(?i)true.grit")]
  
  
  d_comb[str_detect(surl, "(?i)true.grit")]
  
  d[is.na(surl)][1][, by = 'tomatourl', murl := link_conversion(remDr, tomatourl)$murl][]
  
  # d[!J(d_comb[!is.na(imdbid), unique(imdbid)]), on = 'imdbid']
  
  
  
  d_comb[str_detect(surl, "interstellar"), unique(surl)]
  
  d_dtls[imdbid == "tt4168808"]
  # d_fix_movies[1, by = 'surl', murl := link_conversion(remDr, surl)$murl]
  
}

## 03t junk ####

## Old Code ####
## _First method ####
if (FALSE) {
  if (method1) {
    d_data <- f_read_lines(tomato_file)[[1]]
    if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
    d_data[, JSON := rep(list(), .N)]
    # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
    d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
    f_asDT <- \(l) {
      d <- as.data.table(l)
      if (is.list(d$user_links)) d[, user_links := unlist(user_links)] else d
    }
    d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
    d_rbl <- d_data[, rbindlist(DATA, fill = T)]
  } else {
  }
  if (method1) {
    if (F) {
      surl <- d[nrow(d) - 10000, tomatourl]
      surl <- d[i, tomatourl]
      surl <- "/m/forgotten_city/"
      data_file <- tomato_file
      rd <- remDr
    }
    getMovieUserList <- function(rd, surl, data_file, sv = TRUE, 
                                 nlimit = 50, v = FALSE) {
      trim_txt <- "https://www.rottentomatoes.com"
      appd_txt <- "reviews?type=user"
      nav_url <- paste0(trim_txt, surl, appd_txt)
      err <- tryCatch({
        rd$navigate(nav_url)
      }, error = function(e) e)
      
      if (inherits(err, "error")) { #$message
        l_lp <- list(surl = surl, nexti = 0, user_links = "")
        if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
        return(list(surl = surl, nexti = 0))
      }
      if (exists('err',inherits = F)) rm(list = 'err', inherits = F)
      
      xp_users <- '//*[@class="audience-reviews__name"]'
      nexti <- 0L
      sleep_time <- 0.4
      repeat { # browser()
        if (v) cat("\tnexti: ", nexti, "| st: ", sleep_time, "\n")
        nexti <- nexti + 1L
        fe_lp <- rd$findElements(using = "xpath", xp_users)
        if (length(fe_lp) == 0L) {
          l_lp <- list(surl = surl, nexti = nexti, user_links = "")
          if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
          break
        }
        err <- tryCatch({
          up_lp <- unlist(sapply(fe_lp, function(x) x$getElementAttribute('href')))
        }, error = function(e) e)
        
        if (inherits(err, "error")) { #$message
          sleep_time <- sleep_time + 0.1
          nexti <- nexti - 1L
          next
        }
        
        up_lp <- str_remove(up_lp, trim_txt)
        l_lp <- list(surl = surl, nexti = nexti, user_links = up_lp)
        if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
        xp_next <- '//*[contains(@class, "js-prev-next-paging-next")]'
        nbtn <- rd$findElement(using = "xpath", xp_next)
        class_txt <- nbtn$getElementAttribute('class')[[1]]
        if (str_detect(class_txt, " hide ")) break
        if (nexti >= nlimit) break
        
        err <- tryCatch({
          nbtn$clickElement()
        }, error = function(e) e)
        
        if (inherits(err, "error")) { #$message
          cat("Broken Click")
        }
        
        rm(list = ls(pattern = "_lp$"))
        Sys.sleep(sleep_time)
      }
      return(list(surl = surl, nexti = nexti))
    }
    
    for (i in seq(nrow(d))) {  # i=1
      cat("tomatourl: ", d[i, tomatourl], "\n")
      getMovieUserList(remDr, d[i, tomatourl], tomato_file, v = v)
    }
  }
  
}
# getMovieUserList(remDr, "/m/1079818-anastasia/", tomato_file, v = v)

if (FALSE) {
  # xp_next <- '//*[@class="js-prev-next-paging-next btn prev-next-paging__button prev-next-paging__button-right"]'
  ## https://stackoverflow.com/questions/66014309/webscraping-user-reviews-using-scrapy-not-going-to-next-page
  
  xps[[1]]$getElementAttribute('href')
  
  xp <- '/a/@href'
  xp <- '/ul/li[10]/div/a/@href'
  
  
  xp <- '//*[@class="audience-reviews__name"]'
  xps <- remDr$findElements(using = "xpath", xp)
  xps[[1]]$getElementAttribute('href')
  
  
  xp <- '//*[contains(@class, "audience-reviews__name")]'
  xps <- remDr$findElements(using = "xpath", xp)
  xps[[1]]$getElementAttribute('href')
  
  
  xp <- '//*[contains(@class, "audience-reviews__name")]'
  xps <- remDr$findElement(using = "xpath", xp)
  xps$getElementAttribute('href')
  
  xps <- remDr$findElement(using = "link text", "The C")
  xps$getElementAttribute('href')
  
  
  "/html/body/div[5]/div[3]/div[2]/section/div/div/div/ul/li[1]/div[1]/div/a"
  "li.audience-reviews__item:nth-child(1) > div:nth-child(1) > div:nth-child(2) > a:nth-child(1)"
  # href="/user/id/ba0f70b0-127d-4814-a491-f610fddb6316"
  # c("xpath", "css selector", "id", "name", "tag name", "class name", "link text", "partial link text")
  remDr$findElements(using = "tag name", )
  
  # remDr <- remoteDriver(browserName = "chrome")
  # remDr$open()
  # head(remDr$sessionInfo)
  
}

## 04r junk ####

## Defunct Package ####
if (FALSE) {
  # https://stackoverflow.com/questions/24194409/how-do-i-install-a-package-that-has-been-archived-from-cran
  # https://cran.r-project.org/web/packages/htmltidy/index.html
  url <- "http://cran.r-project.org/src/contrib/Archive/RecordLinkage/RecordLinkage_0.4-1.tar.gz"
  save_loc <- file.path(HS_pkgsDir, "htmltidy_0.5.0.tar.gz")
  download.file(url = "https://cran.r-project.org/src/contrib/Archive/htmltidy/htmltidy_0.5.0.tar.gz", destfile = save_loc)
  install.packages(pkgs = save_loc, type = "source", repos = NULL)
  # https://rdrr.io/cran/htmltidy/man/tidy_html.html
  
  if (F) x = topbox
  f_print_html <- \(x) {
    opt_l <- list(TidyXhtmlOut = TRUE, TidyIndentContent = TRUE, TidyTabSize = 5) #, TidyDoctype = "auto"
    htmltidy::tidy_html(x$getElementAttribute("outerHTML")[[1]][1], options = opt_l) %>% cat
    return(NULL)
  }
  
}

# el_lp <- rd$findElements(using = "xpath", review_panals_xp)
# pre_len <- length(el_lp)
# d_lp <- d.t(tm = proc.time()['elapsed'], nexti = nexti, revn = pre_len)
# if (v) cat("\tnexti: ", nexti, "| len: ", pre_len, "\n")
# d_hold <- rbind(d_hold, d_lp)
# for (i in 1) {
#   rd$executeScript("window.scrollTo(0, document.body.scrollHeight);")
#   rd$executeScript("window.scrollBy(0,document.body.scrollHeight)")
#   rd$executeScript("return window.pageYOffset;")
#   rd$executeScript("return document.body.scrollHeight;")
#   Sys.sleep(1)
# }
# el_lp <- rd$findElements(using = "xpath", review_panals_xp)
# pst_len <- length(el_lp)

# busy_wd <- rd$findElements(using = "xpath", busy_xp)
# isBusy <- identical(busy_wd, list())
# if (!isBusy) busytimes <- 0L else busytimes <- busytimes + 1L
# rm(list = c('d_lp', 'el_lp'))
# 
# catn("isBusy:", isBusy, " | busytimes:", busytimes)
# if (busytimes == 0 & pre_len == pst_len) {
#   next
# } else if (pre_len == pst_len) {
#   if (busytimes > 10) break
#   
# }

## Old Code ####

# if (FALSE) {
#   d_data <- f_read_lines(tomato_file)[[1]]
#   if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
#   d_data[, JSON := rep(list(), .N)]
#   # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
#   d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
#   f_asDT <- function(l) {
#     d <- as.data.table(l)
#     if (is.list(d$user_links)) d[, user_links := unlist(user_links)] else d
#   }
#   d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
#   d_rbl <- d_data[, rbindlist(DATA, fill = T)]
#   
#   d_rbl <- d_rbl[!(str_detect(user_links, "^$") | is.na(user_links))]
#   d_rbl <- d_rbl[!duplicated(d_rbl[, .(surl, user_links)])]
#   
#   appd_txt <- "reviews?type=user"
#   d_rbl[, surl := str_remove(surl, trim_url)]
#   d_rbl[, surl := str_remove(surl, fixed(trim_url_RE))]
#   saveRDS(d_rbl, tomado_Rds)
# } else if (TRUE) {
#   d_rbl <- readRDS(tomado_Rds)
# }

# if (TRUE) {
#   d_data <- data.table(raw = character(), i = integer(), fn = character())
#   for (tom in tomato2_files) { ##  tom=tom_fl[1]  tom=tom_fl[2]
#     fn_lp <- str_extract(tom, "(?<=[\\\\/])[^\\\\/]+(?=\\.[[:alnum:]]{1,10}$)")
#     d_lp <- f_read_lines(tom)[[1]][, fn := fn_lp]
#     d_data <- rbind(d_data, d_lp, fill = T)
#     rm(list = ls(pattern = "_lp$"))
#   }
#   if (nrow(d_data) != 0) {
#     if ('JSON' %in% names(d_data)) d_data[, JSON := NULL]
#     d_data[, JSON := rep(list(), .N)]
#     # d_data[1:1000, JSON := lapply(raw, af(x, jsonlite::fromJSON(x)))]
#     d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
#     f_asDT <- \(l) {
#       d <- as.data.table(l)
#       if (is.list(d$uurl)) d[, uurl := unlist(uurl)] else d
#     }
#     d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
#     d_rbl <- d_data[, rbindlist(DATA, fill = T)]
#     d_rbl <- d_rbl[!isTRUE(nexti == 0L), !c('nexti', 'user_links')]
#     setnames(d_rbl, str_remove(names(d_rbl), "^reviews\\."))
#     d_rbl <- d_rbl[!(str_detect(uurl, "^$") | is.na(uurl))]
#     d_rbl <- d_rbl[!duplicated(d_rbl[, .(surl, uurl)])]
#     d_rbl[, surl := str_remove(surl, trim_url_RE)]
#     d_rbl[, surl := str_remove(surl, fixed(appd_txt))]
#     setnames(d_rbl, 'uurl', 'user_links')
#   }
# }
# setnames(d_rbl, 'user_links', 'user_link')


# d_data <- f_read_lines(user_file)[[1]]
# d_data[, JSON := rep(list(), .N)]
# d_data[, JSON := pbapply::pblapply(raw, function(x) jsonlite::fromJSON(x))]
# f_asDT <- function(l) {
#   d <- as.data.table(l)
#   if (is.list(d$user_links)) d[, user_links := unlist(user_links)] else d
# }
# d_data[, DATA := pbapply::pblapply(JSON, f_asDT)]
# if (F) d_data[, sapply(DATA, nrow) == 1L] %>% d_data[.]
# d_data <- d_data[!d_data[, sapply(DATA, nrow) == 1L]]
# d_rbl <- d_data[, rbindlist(DATA, fill = T)]
# setnames(d_rbl, str_remove(names(d_rbl), "^reviews\\."))
# d_rbl <- d_rbl[!duplicated(d_rbl[, .(user_link, surl)])]


if (FALSE) { ## Node-wise SLOW ###
  a <- proc.time()
  if (T) {
    user_rating_xp <- "//section[@class='ratings__review-top']"
    rev_topbox_lp <- rd$findElements(using = "xpath", user_rating_xp)
    lapply(rev_topbox_lp, f_extract_review)
    
  } else {
    user_movie_reviews_l <- f_extract_vector_review(rd, uurl)
    toJSON(user_movie_reviews_l, simplifyVector = F, flatten = F)
  }
  b <- proc.time() - a
}
# saveRDS(d_hold, "C:/Users/rbruner/Desktop/refresh-pace.Rds")


# <img src="https://static-assets.qualtrics.com/static/prototype-ui-modules/SharedGraphics/siteintercept/svg-close-btn-black-7.svg">
# x <- rd$findElement(using = 'xpath', "//div[@style='position: absolute; top: 0px; left: 0px; width: 17px; height: 17px; overflow: hidden; display: block;']")

# x2 <- xml2::xml_find_all(x, xpath = "//a[@class='ratings__movie-title']")
# lapply(x2, \(x) xml2::xml_attrs(x, 'href'))
# x <- as.character(pg_xml)
# x_lc <- str_locate_all(x, "(?i)blades of glory")[[1]]
# for (i in seq(nrow(x_lc))) { # i=1
#   i_lp <- x_lc[i,]
#   cat(substring(x, i_lp[1] - 500,  i_lp[1] + 1000), "\n")
# }

# RSelenium:::selKeys$end # End	U+E010 \ue010
# a$sendKeysToElement(RSelenium:::selKeys$end)
# a$sendKeysToElement(RSelenium:::selKeys$end)
# rd$goForwardsendKeysToElement(list(key = "\ue010"))
# debugonce(rd$goForward)
# rd$goForward()
# qpath <- sprintf("%s/session/%s/end", serverURL, sessionInfo[["id"]])
# queryRD(qpath, "POST")

# ml_lp <- unlist(sapply(ml_lp, function(x) x$getElementAttribute('href')))

# xp_stars <- "//span[@class='star-display']/span[contains(@class,'star-display')]"
# ms_lp <- rd$findElements(using = "xpath", xp_stars)
# length(ms_lp)
# ms_lp[[1]]$getElementAttribute('class')

# unlist(sapply(ms_lp, function(x) x$getElementAttribute('class')))


# xp_ratings <- ""
# fe_lp[[length(fe_lp)]]$findElements(using = "xpath", )

if (F) {
  topbox = rev_topbox_lp[[10]]
  f_print_html(topbox)
  topbox$getElementTagName() 
  topbox$getElementText()
  topbox$getElementLocationInView()
  topbox$highlightElement(wait = 75/1000)
  # a <- topbox$findElement(using = "xpath", surl_xp)
  # f_print_html(a)
  # f_print_html(topbox)
  # a$highlightElement(wait = 75/1000)
  # a$getElementAttribute('href')
}
# scr_rk <- create_recode_key(c('2' = "filled", '1' = "half", '0' = "empty"))
f_extract_review <- \(topbox) {
  surl_xp <- "div[@class='ratings__title']/a[@class='ratings__movie-title']"
  a <- topbox$findChildElement(using = "xpath", surl_xp)
  surl_ <- str_remove(a$getElementAttribute('href')[[1]], trim_txt)
  stars_xp <- "div[@class='ratings__rating-stars']/span[@class='star-display']/span[contains(@class,'star-display__')]"
  s <- topbox$findChildElements(using = "xpath", stars_xp)
  s_l <- lapply(s, \(x) x$getElementAttribute('class')[[1]])
  s_v <- str_extract(s_l, "(?<=__)[^ ]+(?=[ ]?|$)")
  scr <- sum(car::recode(s_v, "'filled'=2;'half'=1;'empty'=0", as.numeric = T))
  list(surl = surl_, score = scr)
}
if (F) rd_ = rd
f_extract_vector_review <- \(rd_ = rd, uurl) {
  movie_href_xp = "//a[@class='ratings__movie-title']"
  ml_lp <- rd_$findElements(using = "xpath", movie_href_xp)
  ml_v <- unlist(sapply(ml_lp, function(x) x$getElementAttribute('href')))
  ml_v <- str_remove(ml_v, trim_txt)
  stars_xp <- "//span[@class='star-display']/span[contains(@class,'star-display__')]"
  ms_lp <- rd_$findElements(using = "xpath", stars_xp)
  ms_lp <- unlist(sapply(ms_lp, function(x) x$getElementAttribute('class')))
  st_v <- str_extract(ms_lp, "(?<=__)[^ ]+(?=[ ]?|$)")
  st_v <- car::recode(st_v, scr_rk, as.numeric = T)
  brks_ <- seq(1, length(st_v) + 1L, by = 5)
  brks_f <- cut(seq(st_v), brks_, right = F)
  st_l <- split(st_v, f = brks_f)
  names(st_l) <- ml_v
  sc_v <- sapply(st_l, sum)
  d_r <- as.data.table(list(surl = names(sc_v), rating = sc_v))
  list(user_link = uurl, reviews = d_r)
  # list(user_link = uurl, reviews = list(surl = names(sc_v), rating = sc_v))
  # f_c <- \(u, s, r) c(user_link = u, surl = s, review = r)
  # Map(f_c, uurl, names(sc_v), sc_v, USE.NAMES = F)
}

if (FALSE) {
  
  if (length(fe_lp) == 0L) {
    l_lp <- list(surl = surl, nexti = nexti, user_links = "")
    if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
    break
  }
  err <- tryCatch({
    
    
    
    up_lp <- unlist(sapply(fe_lp, function(x) x$getElementAttribute('href')))
    
    
  }, error = function(e) e)
  
  if (inherits(err, "error")) { #$message
    sleep_time <- sleep_time + 0.1
    nexti <- nexti - 1L
    next
  }
  
  up_lp <- str_remove(up_lp, trim_txt)
  l_lp <- list(surl = surl, nexti = nexti, user_links = up_lp)
  if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
  xp_next <- '//*[contains(@class, "js-prev-next-paging-next")]'
  nbtn <- rd$findElement(using = "xpath", xp_next)
  class_txt <- nbtn$getElementAttribute('class')[[1]]
  if (str_detect(class_txt, " hide ")) break
  if (nexti >= nlimit) break
  
  err <- tryCatch({
    nbtn$clickElement()
  }, error = function(e) e)
  
  if (inherits(err, "error")) { #$message
    cat("Broken Click")
  }
  
  rm(list = ls(pattern = "_lp$"))
  Sys.sleep(sleep_time)
  
}

## 05c junk ####

if (FALSE) {
  d_ <- '
imdbid      tomatourl
"tt0317705" "/m/incredibles"
' %>% fread

RE <- "(?i)incredibles"
RE <- "(?i)crazy.stupid.love" # /m/crazy_stupid_love_2011  tt1570728
RE <- "(?i)pineapple.express" # /m/pineapple_express
d_cov[str_detect(surl, RE) | str_detect(murl, RE)]
d_tos[str_detect(surl, RE), unique(surl)]
d_rev[str_detect(surl, RE), unique(surl)]
d_mov[str_detect(tomatourl, RE) | str_detect(title, RE)]
}
if (FALSE) {
  RE <- "(?i)crazy.stupid.love" # /m/crazy_stupid_love_2011  tt1570728
  res_lp = httr::GET(paste0(api_link, "tt1570728"), httr::timeout(60 * 5)) #, httr::timeout(120)
  data_lp = rawToChar(res_lp$content)
  "https://www.rottentomatoes.com/m/771203531"
  "https://www.rottentomatoes.com/m/crazy_stupid_love_2011"
}

if (FALSE) {
  RE <- "(?i)pineapple.express" # /m/pineapple_express
  ## /m/pineapple_2008 tt0910936
  
}



# set(d_comb, j = str_subset(names(d_comb), "_dx$"), value = NULL)

if (FALSE) {
  d_mov
  d_comb[, by = .(is.na(tomatourl)), .N]
  d_rev[d_mov, on = c(surl = 'tomatourl'), tomatourl := i.tomatourl]
  
  d_fix_movies <- d_comb[is.na(imdbid), .N, surl][order(-N)]#[N > 50]
  
  d_fix_movies
  
  d_mov
  
  d_fix_movies[, surl_RE := str_remove(surl, "/m/")]
  d_fix_movies[, surl_RE := str_replace_all(surl_RE, "[_-]", ".")]
  
  d_fix_found <- data.table()
  for (i in seq(nrow(d_fix_movies))) {
    print(d_fix_movies[i])
    d_lp <- setDT(fuzzyjoin::regex_right_join(d_mov, d_fix_movies[i], by = c(tomatourl = 'surl_RE')))
    d_fix_found <- rbind(d_fix_found, d_lp, fill = T)
    rm(list = ls(pattern = "_lp$"))
  }
  
  
  
  
  
  
  res_lp = httr::GET(paste0(api_link, imdbID_lp), httr::timeout(60 * 5)) 
  data_lp = rawToChar(res_lp$content)
  
  # d[, tomatourl := p0("https://www.rottentomatoes.com", surl)]
  ## FIX THIS ####
  d_mov[str_detect(title, "(?i)incredibles")] # & year == "2010"
  d[str_detect(surl, "(?i)incredibles"), .(surl = unique(surl))]
  
  RE <- "(?i)star.wars.a.new_hope"
  RE <- "(?i)star.wars"
  "https://www.rottentomatoes.com/m/star_wars_a_new_hope"
  RE <- "(?i)interstellar"
  d_comb[str_detect(surl, RE), !c('uurl','rating')][, unique(.SD)]
  
  d_mov[str_detect(tomatourl, RE) | str_detect(title, RE)] # & year == "2010"
  
  
  
}

## Old Code ####

if (FALSE) {
  d_tos[, mv_dx := .I]
  d_rev[, rv_dx := .I]
  # uurl_ <- "/user/id/785140574"
  # intersect(d_tos[uurl == uurl_, surl], d_rev[uurl == uurl_, surl])
  d_mrg <- merge(d_tos, d_rev, by = c('surl','uurl'), all = T)
  d_mrg[, .N, by = .(mv_NA = is.na(mv_dx), rv_NA = is.na(rv_dx))]
  d_mrg[!is.na(rating.x) & !is.na(rating.y)][rating.x != rating.y]
  rm(d_mrg)
}
