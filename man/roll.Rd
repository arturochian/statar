% Generated by roxygen2 (4.0.2): do not edit by hand
\name{roll_lag}
\alias{roll_lag}
\alias{roll_lead}
\title{Apply rolling functions within time intervals}
\usage{
roll_lag(x, FUN, n, along_with = NULL, order_by = NULL, closed = c(TRUE,
  TRUE), min = 1L, ...)

roll_lead(x, FUN, n, along_with = NULL, order_by = NULL, closed = c(TRUE,
  TRUE), min = 1L, ...)
}
\arguments{
\item{x}{a vector or matrix}

\item{FUN}{function to apply on \code{x}}

\item{n}{a numeric specifying the rolling window}

\item{along_with}{use this variable to roll the function based on the  \code{[along_with - n, along_with]} rather than the past \code{n} rows. NA are not accepted}

\item{order_by}{override the default ordering to use another vector}

\item{closed}{Logical of length 2 (recycled) Should interval be closed ? Default to c(TRUE, TRUE)}

\item{min}{An integer. Return NA if the number of observations is strictkly lower than min}

\item{...}{options to pass to the function \code{FUN}}
}
\description{
Apply rolling functions within time intervals
}
\examples{
date  = c(1, 2, 4, 7)
x <- c(1, 1, 1, 1)
roll_lag(x,sum, n = 1, along_with = date)
roll_lag(x,sum, n = 1, along_with = date, min = 2)
roll_lag(x, sum, n = 1, along_with = date)
roll_lag(x, sum, n = 2, along_with = date)
roll_lead(x, sum, n = 1, along_with = date)
roll_lead(x, sum, n = 2, along_with = date)
y <- c(1, 2, 1, 1)
roll_lag(list(x,y), function(z){cov(z[[1]], z[[2]])},  n = 2, along_with = date)
}

