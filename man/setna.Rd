% Generated by roxygen2 (4.0.2): do not edit by hand
\name{setna}
\alias{setna}
\alias{setna_}
\title{fill NA in place based on non missing observations}
\usage{
setna(x, ..., along_with = NULL, by = NULL, roll = TRUE, rollends = if
  (roll == "nearest") c(TRUE, TRUE) else if (roll >= 0) c(FALSE, TRUE) else
  c(TRUE, FALSE))

setna_(x, ..., vars, along_with = NULL, by = NULL, roll = TRUE,
  rollends = if (roll == "nearest") c(TRUE, TRUE) else if (roll >= 0) c(FALSE,
  TRUE) else c(TRUE, FALSE))
}
\arguments{
\item{x}{a data.table}

\item{...}{Variables to fill in. Default to all non grouping variables. See the \link[dplyr]{select} documentation.}

\item{along_with}{Numeric variable along which NAs should be filled. Default to last key. See the \link[dplyr]{select} documentation.}

\item{by}{Groups within which gaps should be fill. Default to keys (or to keys minus last if along_with is unspecified). See the \link[dplyr]{select} documentation.}

\item{roll}{When roll is a positive number, this limits how far values are carried forward. roll=TRUE is equivalent to roll=+Inf. When roll is a negative number, values are rolled backwards; i.e., next observation carried backwards (NOCB). Use -Inf for unlimited roll back. When roll is "nearest", the nearest value is joined to.}

\item{rollends}{A logical vector length 2 (a single logical is recycled). When rolling forward (e.g. roll=TRUE) if a value is past the last observation within each group defined by the join columns, rollends[2]=TRUE will roll the last value forwards. rollends[1]=TRUE will roll the first value backwards if the value is before it. If rollends=FALSE the value of i must fall in a gap in x but not after the end or before the beginning of the data, for that group defined by all but the last join column. When roll is a finite number, that limit is also applied when rolling the end}

\item{vars}{Used to work around non-standard evaluation.}
}
\description{
fill NA in place based on non missing observations
}
\examples{
library(data.table)
DT <- data.table(
 id    = c(1, 1, 1, 1, 2, 2),
 date  = c(1992, 1989, 1991, 1993, 1992, 1991),
 value = c(NA, NA, 3, NA, 3.2, 5.2)
)
DT1 <- copy(DT)
setkey(DT1, id, date)
DT2 <- copy(DT1)
DT3 <- copy(DT1)
setna(DT, value, along_with = date, by = id)
setna(DT1)
setna(DT2, value, rollends = TRUE)
setna(DT3, value, roll = "nearest")
}

