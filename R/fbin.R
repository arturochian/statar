#' Bin a numeric vector and return integer codes for the binning (corresponds to Stata command xtile)
#'
#' @param x A vector
#' @param cutpoints Cutpoints to use when \code{nq} is not specified.  For instance \code{cutpoints = 0.4} creates two groups, one for observations equal or below 0.4, one for observations superior to 0.4. 
#' @param probs A vector of probabilities that an be used instead of cutpoints. Quantiles are computed as the inverse of the empirical distribution function (type = 1)
#' @param n_quantiles A numeric specifying number of quantiles. Can be used instead of cutpoints
#' @param w A variable specifying weight in case the option n_quantiles is specified.
#' @return An integer vector representing groups corresponding to cutpoints. Includes missing values when present in the original vector.
#' @examples 
#' x <- c(NA, 1:10)                   
#' bin(x, n = 3) # 3 groups based on terciles
#' bin(x, probs = c(0.3, 0.7)) # 3 groups based on two quantiles
#' bin(x, cutpoints = c(2, 3)) # 3 groups based on two cutpoints
#' @export
fbin <- function(x, n = NULL, probs = NULL, cutpoints = NULL, w = NULL){
  if (!is.null(n)){
    probs <-  seq(1/n, 1-1/n, length = n -1)
  }
  if (!is.null(probs)){
    if (is.null(w)){
      # compute quantile and bin in one pass by reordering first
      order <- data.table:::forderv(x)
      l_na <- sum(is.na(x))
      l_probs <- length(probs)
      l_x <- length(x)-l_na
      f <- c(0, ceiling(seq_len(l_probs+1)*l_x/(l_probs+1)))
      aux <- rep(c(NA, seq_len(l_probs + 1)), times = c(l_na, diff(f)))
      aux[order] <- aux
      return(aux)
    } else{
      cutpoints <- wtd.quantile(x, probs, type ="i/n", na.rm = TRUE, weights = w)
    }
  }
  .bincode(x, c(-Inf, cutpoints , +Inf) , include.lowest=TRUE)
}


#' @export
#' @rdname fbin
bin <- function(x, n = NULL, probs = NULL, cutpoints = NULL, w = NULL){
  fbin(x = x, n = n, probs = probs, cutpoints = cutpoints, w = w)
}
 


#oldbin <- function(x, n = NULL, probs = NULL, cutpoints = NULL, w = NULL){
#  if (!is.null(n)){
#    probs <-  seq(1/n, 1-1/n, length = n -1)
#  }
#  if (!is.null(probs)){
#    if (is.null(w)){
#     cutpoints <- quantile(x, probs, type =1, na.rm = TRUE)
#    } else{
#      cutpoints <- wtd.quantile(x, probs, type ="i/n", na.rm = TRUE, weights = w)
#    }
#  }
#  .bincode(x, c(-Inf, cutpoints , +Inf) , include.lowest=TRUE)
#}
#
#
#midbin <- function(x, n = NULL, probs = NULL, cutpoints = NULL, w = NULL){
#  if (!is.null(n)){
#    probs <-  seq(1/n, 1-1/n, length = n -1)
#  }
#  if (!is.null(probs)){
#    if (is.null(w)){
#     cutpoints <- fquantile(x, probs, na.rm = TRUE)
#    } else{
#      cutpoints <- wtd.quantile(x, probs, type ="i/n", na.rm = TRUE, weights = w)
#    }
#  }
#  .bincode(x, c(-Inf, cutpoints , +Inf) , include.lowest=TRUE)
#}


