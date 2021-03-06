% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getCoxInfo.R
\name{coxSpecialStrata}
\alias{coxSpecialStrata}
\alias{coxSpecialStrata.coxph}
\alias{coxSpecialStrata.cph}
\alias{coxSpecialStrata.phreg}
\title{Special character for strata in Cox model}
\usage{
coxSpecialStrata(object)

\method{coxSpecialStrata}{coxph}(object)

\method{coxSpecialStrata}{cph}(object)

\method{coxSpecialStrata}{phreg}(object)
}
\arguments{
\item{object}{The fitted Cox regression model object either
obtained with \code{coxph} (survival package), \code{cph}
(rms package), or \code{phreg} (mets package).}
}
\description{
Return the special character used to indicate the strata variables of the Cox model
}
\examples{
\dontrun{
d <- sampleData(1e2, outcome = "survival")
d$entry <- 0

##
library(survival)
mcoxS <- coxph(Surv(time, event) ~ strata(X1)+strata(X2), data = d)
coxSpecialStrata(mcoxS)

##
library(rms)
mcoxS <- cph(Surv(time, event) ~ strat(X1)+strat(X2), data = d, y = TRUE)
coxSpecialStrata(mcoxS)

##
library(mets)
mcoxS <- phreg(Surv(entry, time, event) ~ strat(X1)+strat(X2), data = d)
coxSpecialStrata(mcoxS)
}
}
\author{
Brice Ozenne broz@sund.ku.dk
}
