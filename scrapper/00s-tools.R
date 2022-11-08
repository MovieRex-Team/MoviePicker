# library('Hmisc')
# library('xml2')
# library('odbc')
# library('RPostgreSQL')
library('data.table')
library('stringr')
library('magrittr')
library('progress')
library('RSelenium')
library('netstat')
library('jsonlite')

sav_loc <- "G:\\.shortcut-targets-by-id\\1orOpWnvYfslVRhb5noEdx03SgES6oXdA\\CPS 298 Storage"
movies_file <- file.path(sav_loc, "movie-data.txt")
movies_Rds <- file.path(sav_loc, "movies.Rds")
tomato_file <- file.path(sav_loc, "tomatos.txt")
tomado_Rds <- file.path(sav_loc, "tomatos.Rds")
tomato2_files <- list.files(sav_loc, pattern = "^tomatos2.*\\.txt$", full.names = T)
user_file <- file.path(sav_loc, "userreviews.txt")
conversion_file <- file.path(sav_loc, "conversion.txt")
rotten_file <- file.path(sav_loc, "rotten.txt")

api_link <- "https://www.omdbapi.com/?apikey=f6f19847&tomatoes=true&i="

## Regex ####
trim_url_RE <- "https?://(www\\.)?rottentomatoes.com"
appd_txt <- "reviews?type=user"
FILE_NAME_RE  <- "(?<=[\\\\/])[^\\\\/]+(?=\\.[[:alnum:]]{1,10}$)"
FULL_FNAME_RE <- "(?<=[\\\\/])[^\\\\/]+\\.[[:alnum:]]{1,10}$"

## General Functions ####
p0 <- function(..., collapse = NULL, recycle0 = FALSE) {
  .Internal(paste0(list(...), collapse, recycle0))
}
`%P%` <- function(x, P = NULL) print(x, nrows = Inf)
f_read_lines <- function(file = NULL, text = NULL) {
  if (is.null(file) & is.null(text)) stop("Must imput data")
  
  if (is.null(file)) {
    # msg <- "Arg 'text' must be a character string or vector of strings."
    # assert(is.chr(text), msg)
    d_ <- tryCatch({
      fread(text = text, sep = "", header = F, strip.white = F)
    }, error = function() {
      d.t(raw = character(), i = integer())
    })
    # browser(expr = ncol(d_) == 0)
    if (ncol(d_) != 0) setnames(d_, 'raw')
    d_[, i := .I]
    return(list(text = d_[]))
  }
  
  # msg <- c("Not all inputs are considered paths. Did you mean to use the ",
  #          "'text' argument instead?")
  # assert(all(sapply(file, is.path)), p00(msg))
  
  .read_lines <- function(fp) {
    fp_ext <- stringr::str_to_lower(tools::file_ext(fp))
    d_doc <- switch(
      fp_ext,
      r = ,
      csv = ,
      txt = , dat = {
        # browser()
        # delim <- detect_deliminator(fp)
        d_ <- fread(file = fp, sep = "", header = F, strip.white = F)
        # browser(expr = ncol(d_) == 0)
        if (ncol(d_) != 0) setnames(d_, 'raw')
        d_
      },
      pdf = {
        lines_v <- pdftools::pdf_text(fp)
        d_ <- fread(text = lines_v, sep = "", header = F, strip.white = F)
        setnames(d_, 'V1', 'raw'); d_
      },
      stop("File ext '", fp_ext, "' has no structure parse method yet.")
    )[, i := .I]
    d_doc[]
  }
  sapply(file, .read_lines, USE.NAMES = T, simplify = F)
}
create_recode_key <- function(x) {
  if (F) x <- setNames(LETTERS[1:6], c(1,Inf, NaN, NA, "NA"))
  if (!assertthat:::is.named(x) | !is.atomic(x)) stop("Requires named atomic vector.")
  xv <- unname(x)
  xv <- if (is.character(x)) paste0("\'", xv, "\'") else xv
  xn <- names(x)
  xs <- if (all(Hmisc::numeric.string(xn))) as.numeric(xn) else paste0("\'", xn, "\'")
  xs[is.na(xn)] <- NA
  # xs[is.nan(xn)] <- NaN
  # xs[is.infinite(xn)] <- 
  paste0(xv, "=", xs, collapse = ";")
}
has.rows <- function(x) if (is.null(nrow(x))) FALSE else TRUE
has.0rows <- function(x) if (has.rows(x)) nrow(x) == 0 else FALSE
isT <- function(x) identical(x, TRUE)
isTRUE <- function(x) vapply(x, FUN = isT, FUN.VALUE = TRUE, USE.NAMES = FALSE)

has.a_duplicate <- function(x, incomparables = FALSE, ...) {
  UseMethod("has.a_duplicate")
}
has.a_duplicate.default <- function(x, incomparables = FALSE, nmax = NA, ...) {
  base::duplicated(x, fromLast = FALSE, ...) | base::duplicated(x, fromLast = TRUE, ...)
}
has.a_duplicate.data.frame <- function(x, incomparables = FALSE, nmax = NA, ...) {
  duplicated(x, fromLast = FALSE, ...) | duplicated(x, fromLast = TRUE, ...)
}
has.a_duplicate.data.table <- function(x, incomparables = FALSE, nmax = NA, ...) {
  duplicated(x, fromLast = FALSE, ...) | duplicated(x, fromLast = TRUE, ...)
}

buffer_integers <- function(x, zeros = NULL, buff_char = c("0", " ", "_")) {
  buff_char <- first(buff_char)
  # if (nchar(buff_char)!=0) stop("buff_char ", buff_char, " must be 1 char.")
  x_ <- as.vector(x)
  zeros <- zeros %||% max(nchar(x_[Hmisc::numeric.string(x_)]))
  x_b <- Hmisc::numeric.string(x_)
  x_set <- stringr::str_pad(x_[x_b], zeros, pad = buff_char)
  x_[x_b] <- x_set
  return(x_)
}

duplicate_index <- function(x, decimal_subdivide = F) {
  if (is.vector(x)) {
    x <- data.table(x)
  }
  if (is.data.frame(x)) {
    if (!is.data.table(x)) x <- as.data.table(x)
    nC <- ncol(x)
    if (decimal_subdivide) {
      d_grp <- copy(x)[has.a_duplicate(get('x'))
                       , by = names(x), `:=`(grp = .GRP, iter = seq.int(.N))][
                         , (nC + 1L):(nC + 2L), with = F]
      d_grp[!is.na(grp), out := as.numeric(p0(grp, ".", buffer_integers(iter)))]
      return(d_grp[['out']])
    } else {
      d_grp <- copy(x)[has.a_duplicate(get('x')), 
                       by = names(x),`:=`(grp = .GRP)][
                         , (nC + 1L), with = F]
      return(d_grp[[1]])
    }
  }
  stop("duplicate_index requires 'x' to be a single vector or data.table.")
}

tsub <- function(X, FUN, ...,
                 fill = NA, type.convert = FALSE,
                 give.names = FALSE) {
  ans <- transpose(lapply(X, FUN, ...), fill = fill, ignore.empty = FALSE)
  if (type.convert) ans <- lapply(ans, type.convert, as.is = TRUE)
  if (is.logical(give.names)) {
    if (give.names) setattr(ans, "names", paste("V", seq_along(ans), sep = ""))
  } else {
    setattr(ans, "names", give.names)
  }
  ans
}

chkc <- function(connection = con, envir = parent.frame()) {
  test_qry <- "select TRUE;"
  try(res_test <- RPostgreSQL::dbGetQuery(con, test_qry)[[1]], silent = T)
  if (exists('res_test', inherits = FALSE) && res_test == "1") return(con)
  con_ <- odbc::dbConnect(odbc::odbc(), con@info$sourcename)
  assign_nm <- deparse(substitute(connection))
  assign(assign_nm, con_, envir = envir)
  return(invisible(con_))
}

## Tomato functions ####
if (F) {
  topbox = tb_nodes[[1]]
}
.f_extract_tomato_xml <- \(topbox) {
  # /a[@class='audience-reviews__user-wrap']
  uurl_xp <- "div[@class='audience-reviews__user-wrap']"
  a <- xml2::xml_child(xml2::xml_find_all(topbox, uurl_xp))
  trim_txt <- "https?://(www\\.)?rottentomatoes.com"
  uurl_ <- str_remove(xml2::xml_attr(a, 'href'), trim_txt)
  stars_xp <- "div[@class='audience-reviews__review-wrap']"
  #/span[@class='star-display']/span[contains(@class,'star-display__')]
  s <- xml2::xml_children(xml2::xml_child(xml2::xml_child(xml2::xml_find_all(topbox, stars_xp))))
  s_l <- xml2::xml_attr(s, 'class')
  s_v <- str_extract(s_l, "(?<=__)[^ ]+(?=[ ]?|$)")
  scr <- sum(car::recode(s_v, "'filled'=2;'half'=1;'empty'=0", as.numeric = T))
  # c(surl = surl_, rating = scr)
  data.table(uurl = uurl_, rating = scr)
}

if (F) rd_ = pg_xml
f_extract_tomato_xml <- \(rd_ = pg_xml, surl = surl, nexti = nexti) {
  topbox_xp <- "//li[@class='audience-reviews__item']"
  tb_nodes <- xml2::xml_find_all(rd_, xpath = topbox_xp)
  iter_l <- lapply(tb_nodes, .f_extract_tomato_xml)
  d_r <- rbindlist(iter_l)
  if (nrow(d_r) == 0L) return(NULL)
  d_r[, nexti := nexti][]
  # list(surl = surl, reviews = d_r)
  d_r
}

## TODO: Fix missing reviews like /user/id/901998718 for vector version ##
if (F) rd_ = pg_xml
f_extract_vector_tomato_xml <- \(rd_ = pg_xml, surl = surl, nexti = nexti) {
  movie_href_xp = "//a[@class='audience-reviews__name']"
  # ml_lp <- rd_$findElements(using = "xpath", movie_href_xp)
  ml_lp <- xml2::xml_find_all(rd_, movie_href_xp)
  # ml_v <- unlist(sapply(ml_lp, function(x) x$getElementAttribute('href')))
  ml_v <- sapply(ml_lp, \(x) xml2::xml_attr(x, 'href'))
  # trim_txt <- "https://www.rottentomatoes.com"
  # ml_v <- str_remove(ml_v, trim_txt)
  stars_xp <- "//span[@class='star-display']/span[contains(@class,'star-display__')]"
  # ms_lp <- rd_$findElements(using = "xpath", stars_xp)
  ms_lp <- xml2::xml_find_all(rd_, stars_xp)
  # ms_lp <- unlist(sapply(ms_lp, function(x) x$getElementAttribute('class')))
  ms_lp <- sapply(ms_lp, \(x) xml2::xml_attr(x, 'class'))
  st_v <- str_extract(ms_lp, "(?<=__)[^ ]+(?=[ ]?|$)")
  st_v <- car::recode(st_v, "'filled'=2;'half'=1;'empty'=0", as.numeric = T)
  brks_ <- seq(1, length(st_v) + 1L, by = 5)
  brks_f <- cut(seq(st_v), brks_, right = F)
  st_l <- split(st_v, f = brks_f)
  names(st_l) <- ml_v
  sc_v <- sapply(st_l, sum)
  d_r <- as.data.table(list(uurl = names(sc_v), rating = sc_v, nexti = nexti))
  # list(surl = surl, reviews = d_r)
  d_r
  # # list(user_link = uurl, reviews = list(surl = names(sc_v), rating = sc_v))
  # # f_c <- \(u, s, r) c(user_link = u, surl = s, review = r)
  # # Map(f_c, uurl, names(sc_v), sc_v, USE.NAMES = F)
}

## Review functions ####
if (F) {
  topbox = tb_nodes[[5198]]
  topbox = tb_nodes[[5199]]
  topbox
}
.f_extract_review_xml <- \(topbox) {
  surl_xp <- "div[@class='ratings__title']/a[@class='ratings__movie-title']"
  # a <- topbox$findChildElement(using = "xpath", surl_xp)
  a <- xml2::xml_find_all(topbox, surl_xp)
  # surl_ <- str_remove(a$getElementAttribute('href')[[1]], trim_txt)
  trim_txt <- "https://www.rottentomatoes.com"
  surl_ <- str_remove(xml2::xml_attr(a, 'href'), trim_txt)
  stars_xp <- "div[@class='ratings__rating-stars']/span[@class='star-display']/span[contains(@class,'star-display__')]"
  # s <- topbox$findChildElements(using = "xpath", stars_xp)
  s <- xml2::xml_find_all(topbox, stars_xp)
  # s_l <- lapply(s, \(x) x$getElementAttribute('class')[[1]])
  s_l <- xml2::xml_attr(s, 'class')
  s_v <- str_extract(s_l, "(?<=__)[^ ]+(?=[ ]?|$)")
  scr <- sum(car::recode(s_v, "'filled'=2;'half'=1;'empty'=0", as.numeric = T))
  # c(surl = surl_, rating = scr)
  data.table(surl = surl_, rating = scr)
}

if (F) rd_ = pg_xml
f_extract_review_xml <- \(rd_ = pg_xml, uurl) {
  topbox_xp <- "//section[@class='ratings__review-top']"
  tb_nodes <- xml2::xml_find_all(rd_, xpath = topbox_xp)
  iter_l <- lapply(tb_nodes, .f_extract_review_xml)
  d_r <- rbindlist(iter_l)
  list(user_link = uurl, reviews = d_r)
}

## TODO: Fix missing reviews like /user/id/901998718 for vector version ##
if (F) rd_ = pg_xml
f_extract_vector_review_xml <- \(rd_ = pg_xml, uurl) {
  movie_href_xp = "//a[@class='ratings__movie-title']"
  # ml_lp <- rd_$findElements(using = "xpath", movie_href_xp)
  ml_lp <- xml2::xml_find_all(rd_, movie_href_xp)
  # ml_v <- unlist(sapply(ml_lp, function(x) x$getElementAttribute('href')))
  ml_v <- sapply(ml_lp, \(x) xml2::xml_attr(x, 'href'))
  trim_txt <- "https://www.rottentomatoes.com"
  ml_v <- str_remove(ml_v, trim_txt)
  stars_xp <- "//span[@class='star-display']/span[contains(@class,'star-display__')]"
  # ms_lp <- rd_$findElements(using = "xpath", stars_xp)
  ms_lp <- xml2::xml_find_all(rd_, stars_xp)
  # ms_lp <- unlist(sapply(ms_lp, function(x) x$getElementAttribute('class')))
  ms_lp <- sapply(ms_lp, \(x) xml2::xml_attr(x, 'class'))
  st_v <- str_extract(ms_lp, "(?<=__)[^ ]+(?=[ ]?|$)")
  st_v <- car::recode(st_v, "'filled'=2;'half'=1;'empty'=0", as.numeric = T)
  brks_ <- seq(1, length(st_v) + 1L, by = 5)
  brks_f <- cut(seq(st_v), brks_, right = F)
  st_l <- split(st_v, f = brks_f)
  # if (FALSE) { which(sapply(st_l, extract, 1) == 0) table(sapply(st_l,
  # length)) range(sapply(st_l, sum)) sc_v <- sapply(st_l, sum) length(st_v) / 5
  # length(sc_v) length(ml_v) length(iter_l) d_ <- data.table(i = seq(ml_v), m =
  # ml_v) d2_ <- data.table(i = seq(sc_v), s = sc_v) d_[d2_, on = 'i', s := s]
  # ml2_v <- sapply(iter_l, \(x) x$surl) d2_ <- data.table(i = seq(ml2_v), m2 =
  # ml2_v) d_[d2_, on = 'i', m2 := m2] sc2_v <- sapply(iter_l, \(x) x$score) d2_
  # <- data.table(i = seq(sc2_v), s2 = sc2_v) d_[d2_, on = 'i', s2 := s2]
  # d_[is.na(s), s := -1] d_[is.na(s2), s2 := -1] d_[m != m2 | s != s2]
  # length(st_l) head(ml_v, 10) tail(ml_v, 10) str_subset(ml_v,
  # "^/m/[^/]*[/][^/]*") }
  names(st_l) <- ml_v
  sc_v <- sapply(st_l, sum)
  d_r <- as.data.table(list(surl = names(sc_v), rating = sc_v))
  list(user_link = uurl, reviews = d_r)
  # # list(user_link = uurl, reviews = list(surl = names(sc_v), rating = sc_v))
  # # f_c <- \(u, s, r) c(user_link = u, surl = s, review = r)
  # # Map(f_c, uurl, names(sc_v), sc_v, USE.NAMES = F)
}
