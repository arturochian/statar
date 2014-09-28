#' Lead and lag.
#'
#' Lead and lag are useful for comparing values offset by a constant (e.g. the
#' previous or next value)
#'
#' @param x a vector of values
#' @param n a postive integer of length 1, giving the number of positions to
#'   lead or lag by
#' @param default value used for non-existant rows. Defaults to \code{NA}.
#' @param order_by override the default ordering to use another vector
#' @param ... Needed for compatibility with lag generic.
#' @importFrom stats lag
#' @examples
#' lead(1:10, 1)
#' lead(1:10, 2)
#'
#' lag(1:10, 1)
#' lead(1:10, 1)
#'
#' x <- runif(5)
#' cbind(ahead = lead(x), x, behind = lag(x))
#'
#' # Use order_by if data not already ordered
#' df <- data.frame(year = 2000:2005, value = (0:5) ^ 2)
#' scrambled <- df[sample(nrow(df)), ]
#'
#' wrong <- mutate(scrambled, prev = lag(value))
#' arrange(wrong, year)
#'
#' right <- mutate(scrambled, prev = lag(value, order_by = year))
#' arrange(right, year)

#' # Use along if unbalanced panel data

#' @name lead-lag
NULL

#' @export
#' @rdname lead-lag
lead <- function(x, n = 1L, default = NA, order_by = NULL, along_with = NULL, ...) {
  if (!is.null(order_by)) {
    if (!is.null(along_with)) stop("order_by and along_with cannot be specified together")
    return(with_order(order_by, lead, x, n = n, default = default))
  }

  if (n == 0) return(x)
  if (n < 0 || length(n) > 1) stop("n must be a single positive integer")

  if (!is.null(along_with)) {
    index <- match(along_with + n, along_with, incomparable = NA)
    out <- x[index]
    if (!is.na(default)) out[which(is.na(index))] <- default
  } else{
    xlen <- length(x)
    n <- pmin(n, xlen)
    out <- c(x[-seq_len(n)], rep(default, n))
  }
  attributes(out) <- attributes(x)
  out
}

#' @export
#' @rdname lead-lag
lag.default <- function(x, n = 1L, default = NA, order_by = NULL, along_with = NULL, ...) {
  if (!is.null(order_by)) {
    if (!is.null(along_with)) stop("order_by and along_with cannot be specified together")
    return(with_order(order_by, lag, x, n = n, default = default))
  }

  if (n == 0) return(x)
  if (n < 0 || length(n) > 1) stop("n must be a single positive integer")

  if (!is.null(along_with)) {
    index <- match(along_with - n, along_with, incomparable = NA)
    out <- x[index]
    if (!is.na(default)) out[which(is.na(index))] <- default
  } else{
    xlen <- length(x)
    n <- pmin(n, xlen)
    out <- c(rep(default, n), x[seq_len(xlen - n)])
  }
  attributes(out) <- attributes(x)
  out
}