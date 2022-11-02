source(file.path(getwd(), "00l-loaders.R"))
v <- T

d_tos <- tos_load()
d_Nusers <- d_tos[, .(uurl, surl)][, unique(.SD)][
  , by = 'uurl', .N][order(-N)]

d_rev <- rev_load()
d_Nrev <- d_rev[, .N, by = 'uurl'][order(-N)]
d_Nusers[d_Nrev, on = 'uurl', ratings := i.N]
d_remains <- d_Nusers[is.na(ratings) | ratings < 80]

script_loc <- file.path(rstudioapi::getActiveDocumentContext()$path, "..")
ahk_fp <- file.path(script_loc, "Mouse AutoHotkey Script.ahk")
ahk_fp %<>% normalizePath()
shell.exec(ahk_fp)
message("Activate on browser page with <ctrl><shift><alt><p>. <Esc> to stop.")

# d_rbl$user_links %>% describe_features(max_table_rows = 100, return_simple_table = T)

# "/user/id/911733308"

# "/user/id/970115043"


## https://www.r-bloggers.com/2021/05/r-selenium/
## https://github.com/mozilla/geckodriver/releases/download/v0.31.0/geckodriver-v0.31.0-win64.zip
## Extract gecho
## https://selenium-release.storage.googleapis.com/4.0/selenium-server-standalone-4.0.0-alpha-2.jar
## Put sel server in gecho folder
## Turn on from terminal ##

"cd C:\\Users\\rbruner\\Desktop\\selenium-server-standalone-4.0.0-alpha-2"
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
  d_ <- d#[N == 30]
  uurl <- d_[1, user_link]
  estN <- d_[1, N]
  uurl <- "/user/id/858208477"
  estN <- 270
  # surl <- d[i, tomatourl]
  data_file <- user_file
  rd <- remDr
  sv = F; v = T
}

getUserList <- function(rd, uurl, estN, data_file, sv = TRUE, v = FALSE) {
  data_file <- normalizePath(data_file)
  # browser()
  trim_txt <- "https://www.rottentomatoes.com"
  appd_txt <- "/ratings"
  nav_url <- paste0(trim_txt, uurl, appd_txt)
  err <- tryCatch({
    rd$navigate(nav_url)
  }, error = function(e) e)
    # XML::htmlParse(rd$getPageSource()[[1]])
  if (inherits(err, "error")) { #$message
    d_empty <- data.table(surl = "", rating = 0L)
    l_lp <- list(user_link = uurl, reviews = d_empty)
    if (sv) cat(toJSON(l_lp), sep = "\n", file = data_file, append = TRUE)
    return(list(user_link = uurl, nexti = 0L, nrev = 0L))
  }
  
  if (exists('err', inherits = F)) rm(list = 'err', inherits = F)
  blk_x_xp <- "//img[@src='https://static-assets.qualtrics.com/static/prototype-ui-modules/SharedGraphics/siteintercept/svg-close-btn-black-7.svg']"
  suppressMessages({
    try({button_we <- rd$findElement(using = 'xpath', blk_x_xp)}, silent = T)
  })
  if (exists('button_we')) button_we$clickElement()
  
  # review_panals_xp <- "//li[@class='ratings__user-rating-review']"
  busy_xp <- "//div[@class='js-scroll-anchor infinite-scrolling__bottom--busy']"
  # rd$executeScript("window.scrollTo(0, document.body.scrollHeight)")
  sleep_time <- .3
  min_time <- .1
  nexti <- 0L
  busy_cnt <- 0L
  pre_height <- 0L
  last_height <- 0L
  # d_hold <- data.table(tm = proc.time()['elapsed'], nexti = nexti, pren = 0) #, pstn = 0
  repeat { # browser()
    if (v) cat("nexti:", nexti, "| sleep_time:", sleep_time, "| last_height:", last_height)
    nexti <- nexti + 1L
    pre_height <- rd$executeScript("return document.body.scrollHeight;")[[1]]
    if (pre_height == last_height) {
      busy_wd <- NULL
      suppressMessages({
        try({busy_wd <- rd$findElement(using = "xpath", busy_xp)}, silent = T)
      })
      isBusy <- !is.null(busy_wd)
      if (v) cat(" | isBusy:", isBusy)
      sleep_time <- sleep_time + 0.3
      if (!isBusy) {
        if (v) cat(" | busy_cnt:", busy_cnt)
        if (sleep_time > 3) {
          if (v) cat(" | sleep_time>3 break\n")
          break
        }
        if (busy_cnt > 3L) {
          Sys.sleep(.2)
          if (v) cat(" | busy_cnt>3L next\n")
          next
        }
        busy_cnt <- busy_cnt + 1L
      } else {
        if (sleep_time > 4.4) {
          if (v) cat(" | sleep_time>4.4 break\n")
          break
        }
      }
    } else {
      if (sleep_time > min_time) sleep_time <- sleep_time - 0.05
      busy_cnt <- 0L
    }
    last_height <- pre_height
    rd$executeScript("window.scrollBy(0,document.body.scrollHeight)")
    # d_lp <- data.table(tm = proc.time()['elapsed'], 
    #                    nexti = nexti, 
    #                    pren = pre_height) #,  pstn = pst_height
    # d_hold <- rbind(d_hold, d_lp)
    Sys.sleep(sleep_time)
    # if (sleep_time > 2) break
    if (v) cat("\n")
  }
  
  pg_src <- rd$getPageSource()[[1]]
  # pg_src <- readRDS("C:\\Users\\rbruner\\Desktop\\delete.Rds")
  pg_xml <- xml2::read_html(pg_src)
 
  ## Source XML FAST ###
  a <- proc.time()
  umr_l <- NULL
  try(umr_l <- f_extract_vector_review_xml(pg_xml, uurl), silent = T)
  if (is.null(umr_l)) umr_l <- f_extract_review_xml(pg_xml, uurl)
  b <- proc.time() - a
  if (sv) cat("Saving after nexti", nexti, "| Nreviews", nrow(umr_l$reviews), "\n")
  if (sv) cat(toJSON(umr_l), sep = "\n", file = data_file, append = TRUE)
  
  return(list(surl = uurl, nexti = nexti, nrev = nrow(umr_l$reviews)))
}

# d[user_link == "/user/id/911660699", which = T]
for (i in seq(nrow(d_remains))) { # i=352
  cat("\ntomatourl: ", d_remains[i, uurl], " with", d_remains[i, N], "entries.\n")
  getUserList(
    rd = remDr,
    uurl = d_remains[i, uurl],
    estN = d_remains[i, N],
    user_file,
    v = T
  )
  Sys.sleep(1)
}
