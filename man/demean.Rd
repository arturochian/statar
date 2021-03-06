% Generated by roxygen2 (4.0.2): do not edit by hand
\name{demean}
\alias{demean}
\title{Demean a vector}
\usage{
demean(x, fe)
}
\arguments{
\item{x}{A vector, a list of vector, or a data.frame}

\item{fe}{List of vectors for group (factor, characters or integers)}
}
\value{
A demeaned vector

An object of the same type than `x` (ie vector, list or data.frame) where each vector is replaced by its demaned version.
}
\description{
Demean a vector
}
\details{
This function calls felm::demeanlist after dealing with missing values and converting group variables into factors
}
\examples{
demean(c(1,2), fe = c(1,1))
demean(c(NA,2), fe = list(c(1,2), c(1,3)))
demean(c(1,2), fe = list(c(NA,2), c(1,3)))
demean(list(c(1,2),c(1,4)), fe = list(c(NA,2), c(1,3)))
}

