% Generated by roxygen2 (4.0.2): do not edit by hand
\name{setmutate_each}
\alias{setmutate_each}
\alias{setmutate_each_}
\title{Version of mutate_each that (i) transforms data.table in place (ii) allows by, i condition (iii) when only when fun, creates new variables - except when replace = TRUE}
\usage{
setmutate_each(x, funs, ..., i = NULL, by = NULL, replace = FALSE)

setmutate_each_(x, funs, vars, i = NULL, by = NULL, replace = FALSE)
}
\arguments{
\item{x}{a data.table}

\item{funs}{List of function calls, generated by funs, or a character vector of function names.}

\item{...}{Variables to include. Defaults to all non-grouping variables.}

\item{i}{a condition that restricts the set of row on which to apply the function}

\item{by}{Groups within which the function should be applied}

\item{replace}{If replace = TRUE, variables are replaced. Default to FALSE (new variable are created)}

\item{vars}{Used to work around non-standard evaluation.}
}
\description{
Version of mutate_each that (i) transforms data.table in place (ii) allows by, i condition (iii) when only when fun, creates new variables - except when replace = TRUE
}
\examples{
library(data.table)
library(dplyr)
N <- 100
DT <- data.table(
  id = sample(5, N, TRUE),
  v1 = sample(5, N, TRUE),
  v2 = sample(1e6, N, TRUE)
)
setmutate_each(DT, funs(mean, mean_na = mean(., na.rm = TRUE)), v2, i = id ==1, by = v1)
setmutate_each(DT, funs(as.character), replace = TRUE)
}

