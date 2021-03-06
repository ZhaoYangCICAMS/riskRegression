% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/autoplot.ate.R
\name{autoplot.ate}
\alias{autoplot.ate}
\title{Plot predictions from a Cause-specific Cox proportional hazard regression}
\usage{
\method{autoplot}{ate}(object, ci = FALSE, band = FALSE, plot = TRUE,
  digits = 2, alpha = 0.1, ...)
}
\arguments{
\item{object}{object obtained with the function \code{predictCox}.}

\item{ci}{Logical. If \code{TRUE} display the confidence intervals for the predictions.}

\item{band}{Logical. If \code{TRUE} display the confidence bands for the predictions.}

\item{plot}{Logical. Should the graphic be plotted.}

\item{digits}{integer indicating the number of decimal places}

\item{alpha}{transparency of the confidence bands. Argument passed to \code{ggplot2::geom_ribbon}.}

\item{...}{not used. Only for compatibility with the plot method.}
}
\description{
Plot predictions from a Cause-specific Cox proportional hazard regression
}
\examples{
library(survival)
library(rms)

set.seed(10)
n <- 1e2

## Cox model
dtS <- sampleData(n,outcome="survival")

fit=cph(formula = Surv(time,event)~ X1+X2,data=dtS,y=TRUE,x=TRUE)

seqTimes <- sort(unique(fit$y[,1]))
seqTimes5 <-seqTimes[seqTimes>5 & seqTimes<10]
ateFit <- ate(fit, data = dtS, treatment = "X1", contrasts = NULL,
              times = seqTimes, B = 0, band = TRUE, nsim.band = 500, y = TRUE, mc.cores=1)
autoplot(ateFit, band = TRUE, ci = TRUE)

}
