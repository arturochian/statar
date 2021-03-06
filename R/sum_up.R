#' Gives summary statistics (corresponds to Stata command summarize)
#' 
#' @param x a data.table
#' @param ... Variables to include. Defaults to all non-grouping variables. See the \link[dplyr]{select} documentation.
#' @param w Weights. Default to NULL. 
#' @param i Condition
#' @param by Groups within which summary statistics are printed. Default to NULL. See the \link[dplyr]{select} documentation.
#' @param d Should detailed summary statistics be printed?
#' @param na.rm A boolean. default to TRUE
#' @param digits Number of significant decimal digits. Default to 3
#' @param vars Used to work around non-standard evaluation.
#' @examples
#' library(data.table)
#' N <- 100
#' DT <- data.table(
#'   id = 1:N,
#'   v1 = sample(5, N, TRUE),
#'   v2 = sample(1e6, N, TRUE)
#' )
#' sum_up(DT)
#' sum_up(DT, v2, d = TRUE)
#' sum_up(DT, starts_with("v"), by = v1)
#' sum_up(DT, by = v1)
#' @export
sum_up <- function(x, ...,  d = FALSE, w = NULL,  i = NULL, by = NULL, digits = 3) {
  UseMethod("sum_up")
}

#' @export
sum_up.default <- function(x, ...,  d = FALSE, w = NULL, na.rm = TRUE, digits = 3) {
  xsub <- copy(deparse(substitute(x)))
  if (is.null(w)){
    x <- list(x)
    setnames(setDT(x), xsub)
    print(x)
    sum_up.data.table(x, one_of(xsub), d = d, na.rm = na.rm, digits = digits)
  } else{
    x <- list(x, w)
    setnames(setDT(x),  c(xsub, "weight"))
    sum_up.data.table(x, one_of(xsub), d = d, w = weight, na.rm = na.rm, digits = digits)
  }
}

#' @export
sum_up.data.table <- function(x, ...,  d = FALSE, w = NULL,  i = NULL, by = NULL, na.rm = TRUE, digits = 3) {
  sum_up_(x, vars = lazy_dots(...) , d = d, w = substitute(w), i = substitute(i), by = substitute(by), digits = digits)
}


#' @export
#' @rdname sum_up
sum_up_<- function(x, vars, d = FALSE,  w= NULL,  i = NULL, by = NULL, digits = 3) {
  stopifnot(is.data.table(x))
  w <- names(select_vars_(names(x), w))
  if (!length(w)) w <- NULL
  byvars <- names(select_vars_(names(x), by))
  dots <- all_dots(vars)
  vars <- names(select_vars_(names(x), dots, exclude = c(w, byvars)))
  if (length(vars) == 0) {
     vars <- setdiff(names(x), c(byvars, w))
  }
  nums <- sapply(x, is.numeric)
  nums_name <- names(nums[nums==TRUE])
  vars <- intersect(vars,nums_name)
  if (!length(vars)) stop("Please select at least one non-numeric variable", call. = FALSE)
  if (!is.null(w)){
    w <- x[[which(names(x)== w)]]
  }
  if (!is.null(i)){
    x <- x[i, c(vars, w, byvars), with = FALSE]
  }
  if (!length(byvars)){
    out <- x[, describe(.SD, d = d, w = w, na.rm = na.rm), .SDcols = vars]
  } else{
    out <- x[, describe(.SD, d = d, w = w, na.rm = na.rm), by = byvars, .SDcols = vars]
  }
  setkeyv(out, c("variable", byvars))
  setcolorder(out, c("variable", byvars, setdiff(names(out), c("variable", byvars))))
  print_pretty_summary(out, digits = digits)
  invisible(out)
}



describe <- function(M, d = FALSE, na.rm = TRUE, w = NULL, mc.cores = getOption("mc.cores", 2)){
  names <- names(M)
  # Now starts the code 
  if (d==FALSE) {
    if (!is.null(w)){
      sum <-mclapply(M ,function(x){
        take <- !is.na(x) & !is.na(w)
        x_omit <- x[take]
        w_omit <- w[take]
        c(length(x_omit), length(x)-length(x_omit), Hmisc::wtd.mean(x_omit, w = w_omit), sqrt(Hmisc::wtd.var(x_omit, w = w_omit)), min(x_omit), max(x_omit))
      })
    }else{
      sum <-mclapply(M ,function(x){
        x_omit <- na.omit(x)
      c(length(x_omit), length(x) - length(x_omit), mean(x_omit), sd(x_omit), min(x_omit), max(x_omit))
      })
    }
    setDT(sum)
    sum <- t(sum)
    sum <- as.data.table(sum)
    sum <- cbind(names, sum)
    setnames(sum, c("variable", "N","N_NA","mean","sd","min", "max"))
  } else {
    N <- nrow(M)
    f=function(x){
      if (!is.null(w)){
        take <- !is.na(x) & !is.na(w)
        x_omit <- x[take]
        w_omit <- w[take]
        m <- Hmisc::wtd.mean(x_omit, w = w_omit)
        sum_higher <- matrixStats::colWeightedMeans(cbind((x_omit-m)^2,(x_omit-m)^3,(x_omit-m)^4), w = w_omit)
        sum_higher[1] <- sqrt(sum_higher[1])
        sum_higher[2] <- sum_higher[2]/sum_higher[1]^3
        sum_higher[3] <- sum_higher[3]/sum_higher[1]^4
        sum_quantile <- fquantile(x_omit, c(0, 0.01, 0.05, 0.1, 0.25, 0.50, 0.75, 0.9, 0.95, 0.99, 1), weights = w_omit)
      } else{
        x_omit <- na.omit(x)
        m <-mean(x_omit)
        sum_higher <- colMeans(cbind((x_omit-m)^2,(x_omit-m)^3,(x_omit-m)^4))
        sum_higher[1] <- sqrt(sum_higher[1])
        sum_higher[2] <- sum_higher[2]/sum_higher[1]^3
        sum_higher[3] <- sum_higher[3]/sum_higher[1]^4
        sum_quantile= fquantile(x, c(0, 0.01, 0.05, 0.1, 0.25, 0.50, 0.75, 0.9, 0.95, 0.99, 1))
      }
      n_NA <- length(x) - length(x_omit)
      sum <- c(N-n_NA, n_NA, m, sum_higher, sum_quantile)
    }
    sum <- mclapply(M, f)
    setDT(sum)
    sum <- t(sum)
    sum <- as.data.table(sum)
    sum <- cbind(names, sum)
    setnames(sum, c("variable", "N","N_NA","mean","sd","skewness","kurtosis","min","1%","5%","10%","25%","50%","75%","90%","95%","99%","max"))
  }
  sum
}



print_pretty_summary <- function(x, digits = 3){
 # f <- function(y){
 #   if (is.numeric(y)){
 #     y <- sapply(y, function(z){.iround(z, decimal.places = digits)})
 #     end <- paste0(paste(rep("0", digits), collapse = ""),"$")
 #     y <- str_replace(y,end,"")
 #     y[y==""] <- "0"
 #     y <- str_replace(y,"\\.$","")
 #     y <- str_replace(y,"^-0$","0")
 #   } 
 #   y
 # }
 # x <- x[, lapply(.SD, f), .SDcols = names(x)]
  if ("skewness" %in% names(x)){
    x1 <-discard_(x, c("`1%`","`5%`","`10%`","`25%`","`50%`","`75%`","`90%`","`95%`","`99%`"))
    x2 <- discard_(x, c("N","N_NA","mean","sd","skewness","kurtosis", "min", "max"))
    stargazer(x1, type = "text", summary = FALSE, digits = digits, rownames = FALSE)
    stargazer(x2, type = "text", summary = FALSE, digits = digits, rownames = FALSE)
  } else{
  stargazer(x, type = "text", summary = FALSE, digits = digits, rownames = FALSE)
  }
}

# import 3 functions from stargazer
#.iround <- function(x, decimal.places = 0, round.up.positive = FALSE, 
#    simply.output = FALSE,  .format.digit.separator = ",") {
#  .format.initial.zero <- TRUE
#  .format.until.nonzero.digit <- TRUE
#  .format.max.extra.digits <- 2
#  .format.digit.separator.where <- c(3)
#  .format.ci.separator <- ", "
#  .format.round.digits <- 3
#  .format.decimal.character <- "."
#  .format.dec.mark.align <- FALSE
#  .format.dec.mark.align <- TRUE
#  x.original <- x
#  first.part <- ""
#  if (is.na(x) | is.null(x)) {
#    return("")
#  }
#  if (x.original < 0) {
#    x <- abs(x)
#  }
#  if (!is.na(decimal.places)) {
#      if ((.format.until.nonzero.digit == FALSE) | (decimal.places <= 
#          0)) {
#          round.result <- round(x, digits = decimal.places)
#      }
#      else {
#          temp.places <- decimal.places
#          if (!.is.all.integers(x)) {
#            while ((round(x, digits = temp.places) == 0) & 
#              (temp.places < (decimal.places + .format.max.extra.digits))) {
#              temp.places <- temp.places + 1
#            }
#          }
#          round.result <- round(x, digits = temp.places)
#          decimal.places <- temp.places
#      }
#      if ((round.up.positive == TRUE) & (round.result < 
#          x)) {
#          if (x > (10^((-1) * (decimal.places + 1)))) {
#            round.result <- round.result + 10^((-1) * decimal.places)
#          }
#          else {
#            round.result <- 0
#          }
#      }
#  }
#  else {
#      round.result <- x
#  }
#  round.result.char <- as.character(format(round.result, 
#      scientific = FALSE))
#  split.round.result <- unlist(strsplit(round.result.char, 
#      "\\."))
#  for (i in seq(from = 1, to = length(.format.digit.separator.where))) {
#      if (.format.digit.separator.where[i] <= 0) {
#          .format.digit.separator.where[i] <<- -1
#      }
#  }
#  separator.count <- 1
#  length.integer.part <- nchar(split.round.result[1])
#  digits.in.separated.unit <- 0
#  for (i in seq(from = length.integer.part, to = 1)) {
#      if ((digits.in.separated.unit == .format.digit.separator.where[separator.count]) & 
#          (substr(split.round.result[1], i, i) != "-")) {
#          first.part <- paste(.format.digit.separator, 
#            first.part, sep = "")
#          if (separator.count < length(.format.digit.separator.where)) {
#            separator.count <- separator.count + 1
#          }
#          digits.in.separated.unit <- 0
#      }
#      first.part <- paste(substr(split.round.result[1], 
#          i, i), first.part, sep = "")
#      digits.in.separated.unit <- digits.in.separated.unit + 
#          1
#  }
#  if (x.original < 0) {
#      if (.format.dec.mark.align == TRUE) {
#          first.part <- paste("-", first.part, sep = "")
#      }
#      else {
#          first.part <- paste("$-$", first.part, sep = "")
#      }
#  }
#  if (!is.na(decimal.places)) {
#      if (decimal.places <= 0) {
#          return(first.part)
#      }
#  }
#  if (.format.initial.zero == FALSE) {
#      if ((round.result >= 0) & (round.result < 1)) {
#          first.part <- ""
#      }
#  }
#  if (length(split.round.result) == 2) {
#      if (is.na(decimal.places)) {
#          return(paste(first.part, .format.decimal.character, 
#            split.round.result[2], sep = ""))
#      }
#      if (nchar(split.round.result[2]) < decimal.places) {
#          decimal.part <- split.round.result[2]
#          for (i in seq(from = 1, to = (decimal.places - 
#            nchar(split.round.result[2])))) {
#            decimal.part <- paste(decimal.part, "0", sep = "")
#          }
#          return(paste(first.part, .format.decimal.character, 
#            decimal.part, sep = ""))
#      }
#      else {
#          return(paste(first.part, .format.decimal.character, 
#            split.round.result[2], sep = ""))
#      }
#  }
#  else if (length(split.round.result) == 1) {
#      if (is.na(decimal.places)) {
#          return(paste(first.part, .format.decimal.character, 
#            decimal.part, sep = ""))
#      }
#      decimal.part <- ""
#      for (i in seq(from = 1, to = decimal.places)) {
#          decimal.part <- paste(decimal.part, "0", sep = "")
#      }
#      return(paste(first.part, .format.decimal.character, 
#          decimal.part, sep = ""))
#  }
#  else {
#      return(NULL)
#  }
#}
#is.wholenumber <- function(x, tol = .Machine$double.eps^0.5) abs(x - 
#    round(x)) < tol
#.is.all.integers <- function(x) {
#    if (!is.numeric(x)) {
#        return(FALSE)
#    }
#    if (length(x[!is.na(x)]) == length(is.wholenumber(x)[(!is.na(x)) & 
#        (is.wholenumber(x) == TRUE)])) {
#        return(TRUE)
#    }
#    else {
#        return(FALSE)
#    }
#}
