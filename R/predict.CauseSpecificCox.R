#' @title Predicting absolute risk from cause-specific Cox models
#' @rdname predict.CauseSpecificCox
#' @aliases predict.CauseSpecificCox
#' @aliases predictBig.CauseSpecificCox
#'
#' @description  Apply formula to combine two or more Cox models into absolute risk (cumulative incidence function)
#' 
#' @param object The fitted cause specific Cox model
#' @param newdata A data frame containing the values of the variables
#'     in the right hand side of 'coxph' for each subject.
#' @param times Vector of times at which to return the estimated
#'     absolute risk.
#' @param cause Identifies the cause of interest among the competing
#'     events.
#' @param landmark the starting time for the computation of the cumulative risk
#' @param keep.times Logical. If \code{TRUE} add the evaluation times
#'     to the output.
#' @param keep.newdata Logical. If \code{TRUE} add the value of the covariates used to make the prediction in the output list. 
#' @param keep.strata Logical. If \code{TRUE} add the value of the strata used to make the prediction in the output list. 
#' @param se Logical. If \code{TRUE} add the standard errors to the output.
#' @param band Logical. If \code{TRUE} add the confidence band to the output.
#' @param iid Logical. If \code{TRUE} add the influence function to the output.
#' @param average.iid Logical. If \code{TRUE} add the average of the influence function over \code{newdata} to the output.
#' @param nsim.band the number of simulations used to compute the quantiles
#' for the confidence bands.
#' @param log.transform Should the confidence intervals/bands be computed on the
#' log(-log) scale and be backtransformed.
#' Otherwise they are computed on the original scale and truncated (if necessary).
#' @param product.limit Logical. If true the survival is computed using the product limit estimator.
#' Otherwise the exponential approximation is used (i.e. exp(-cumulative hazard)).
#' @param conf.level Level of confidence.
#' @param store.iid Implementation used to estimate the influence function and the standard error.
#' Can be \code{"full"} or \code{"minimal"}. 
#' @param ... not used
#' @author Brice Ozenne broz@@sund.ku.dk, Thomas A. Gerds
#'     tag@@biostat.ku.dk
#' @details
#' This function computes the absolute risk as given by formula 2 of (Ozenne et al., 2017).
#' Confidence intervals and confidence bands can be computed using a first order von Mises expansion.
#' See the section "Construction of the confidence intervals" in (Ozenne et al., 2017).
#' 
#' When setting \code{log.transform} to \code{TRUE}, the standard error that is returned is 
#' before back-transformation to the original scale.
#'
#' A detailed explanation about the meaning of the argument \code{store.iid} can be found
#' in (Ozenne et al., 2017) Appendix B "Saving the influence functions".
#' 
#' Note: for Cox regression models with time varying
#'     covariates it does not make sense to use this function, because
#'     the predicted risk has to be a measurable function of the data
#'     available at the time origin.
#' 
#' @return A list containing:
#' \itemize{
#' \item{absRisk}: (data table) the predictions for each subject (in rows) and each time (in columns).
#' \item{absRisk.se}: (data table) the standard errors of the predictions.
#' \item(absRisk.iid): (array) the value of the influence of each subject used to fit the object (dim 3)
#' for each subject in newdata (dim 1) and each time (dim 2).
#' \item(absRisk.average.iid): (matrix) the average value of the influence over the subjects in newdata,
#' for each subject used to fit the object (dim 1) and each time (dim 2).
#' \item{times}: (vector) the evaluation times.
#' }
#'
#' @references
#' Brice Ozenne, Anne Lyngholm Sorensen, Thomas Scheike, Christian Torp-Pedersen and Thomas Alexander Gerds.
#' riskRegression: Predicting the Risk of an Event using Cox Regression Models.
#' The R Journal (2017) 9:2, pages 440-460.
#' 
#' @examples
#' library(survival)
#' 
#' ## generate data
#' set.seed(5)
#' d <- sampleData(80,outcome="comp") ## training dataset
#' nd <- sampleData(4,outcome="comp") ## validation dataset
#' d$time <- round(d$time,1) ## create tied events
#' ttt <- sort(sample(x = unique(d$time), size = 10))
#'
#' ## estimate a CSC model based on the coxph function
#' CSC.fit <- CSC(Hist(time,event)~ X3+X8, data=d, method = "breslow")
#'
#' ## compute the absolute risk of cause 1, in the validation dataset
#' ## at time 1:10
#' CSC.risk <-  predict(CSC.fit, newdata=nd, times=1:10, cause=1)
#' CSC.risk
#'
#' ## add the standard error/confidence intervals
#' ## (computed on the log log scale and backtransformed)
#' CSC.riskSE <-  predict(CSC.fit,newdata=nd,times=1:10,cause=1,se=TRUE,
#'                         log.transform = TRUE)
#' as.data.table(CSC.riskSE)[1:5]
#' exp(-exp(
#'  log(-log(CSC.riskSE$absRisk)) - 1.96 * CSC.riskSE$absRisk.se
#' ))
#'
#' ## extract the iid for the absolute risk
#' CSC.iid <- predict(CSC.fit, newdata = d, se = TRUE,
#'                    cause = 1, times = ttt[1], iid = TRUE,
#'                    log.transform = FALSE)
#' rowMeans(CSC.iid$absRisk.iid[,1,]) ## the iid decomposition has 0 expectation
#' sqrt(rowSums(CSC.iid$absRisk.iid[,1,]^2))[1:5]
#' as.data.table(CSC.iid)[1:5]
#'
#' ## same but the iid decomposition is averaged over the patients
#' CSC.aviid <- predict(CSC.fit, newdata = d,
#'                    cause = 1, times = ttt[1],
#'                    average.iid = TRUE,
#'                    log.transform = FALSE)
#' CSC.aviid$absRisk.average.iid[1:5,]
#' colMeans(CSC.iid$absRisk.iid[,1,1:5])
#' 
#' ## compute absolute risks with CI for cause 2
#' ## (without displaying the value of the covariates)
#' predict(CSC.fit,newdata=nd,times=1:10,cause=2,se=TRUE,
#'         log.transform = TRUE, keep.newdata = FALSE)
#'
#' ## other example
#' library(survival)
#' CSC.fit.s <- CSC(list(Hist(time,event)~ strata(X1)+X2+X9,
#'  Hist(time,event)~ X2+strata(X4)+X8+X7),data=d, method = "breslow")
#' predict(CSC.fit.s,cause=1,times=ttt,se=1L) ## note: absRisk>1 due to small number of observations
#' 
#' ## using the cph function instead of coxph
#' CSC.cph <- CSC(Hist(time,event)~ X1+X2,data=d, method = "breslow", fitter = "cph")#' 
#' predict(CSC.cph, newdata = d, cause = 2, times = ttt)
#' 
#' ## landmark analysis
#' T0 <- 1
#' predCSC_afterT0 <- predict(CSC.fit, newdata = d, cause = 2, times = ttt[ttt>T0], landmark = T0)
#' predCSC_afterT0
#'
#' @method predict CauseSpecificCox
#' @export
predict.CauseSpecificCox <- function(object,
                                     newdata,
                                     times,
                                     cause,
                                     landmark = NA,
                                     keep.times = 1L,
                                     keep.newdata = 1L,
                                     keep.strata = 1L,
                                     se  = FALSE,
                                     band = FALSE,
                                     iid = FALSE,
                                     average.iid = FALSE,
                                     nsim.band = 1e4,
                                     log.transform = TRUE,
                                     product.limit = TRUE,
                                     conf.level=0.95,
                                     store.iid="full",
                                     ...){
    if(object$fitter=="phreg"){newdata$entry <- 0} 
    if(missing(newdata)){newdata <- eval(object$call$data)}
    data.table::setDT(newdata)
    
    surv.type <- object$surv.type
    if (length(cause) > 1){
        stop(paste0("Can only predict one cause. Provided are: ", 
                    paste(cause, collapse = ", "), sep = ""))
    }
    if (missing(cause)) {
        cause <- object$theCause
    }
	
    ## causes
    # NOTE: cannot use only eventtimes of cause 1 otherwise wrong estimation of the survival in the absolute risk
    causes <- object$causes
    index.cause <- which(causes == cause)
    
    ## event times
    eTimes <- object$eventTimes
    
    if (any(match(as.character(cause), causes, nomatch = 0)==0L))
        stop(paste0("Cannot find all requested cause(s) ...\n\n", 
                    "Requested cause(s): ", paste0(cause, collapse = ", "), 
                    "\n Available causes: ", paste(causes, collapse = ", "), 
                    "\n"))
    ## stopifnot(match(as.character(cause), causes, nomatch = 0) != 
    ## 0)
    if (surv.type == "survival") {
        if (object$theCause != cause) 
            stop("Object can be used to predict cause ", object$theCause, 
                 " but not ", cause, ".\nNote: the cause can be specified in CSC(...,cause=).")
    }
    if(any(is.na(times))){
        stop("NA values in argument \'times\' \n")
    }
    if(length(landmark)!=1){
        stop("\'t0\' must have length one \n")
    }
  
    ## Confidence bands
    if(band>0){ # used to force the computation of the influence function + standard error to get the confidence bands
        iid <- TRUE
        se <- TRUE
    }
    # original arguments to make this operation invisible for the user
    iid.save <- iid
    se.save <- se
        
    # relevant event times to use  
    eventTimes <- eTimes[which(eTimes <= max(times))] 
    if(length(eventTimes) == 0){eventTimes <- min(times)} # at least the first event

    # order prediction times
    ootimes <- order(order(times))

    # predict cumulative cause specific hazards
    new.n <- NROW(newdata)
    nEventTimes <- length(eventTimes)
    nCause <- length(causes)

    if (surv.type == "hazard") {
        
        ls.hazard <- vector(mode = "list", length = nCause)
        ls.cumhazard <- vector(mode = "list", length = nCause)
        M.eXb <- matrix(NA, nrow = new.n, ncol = nCause)
        M.strata <- matrix(NA, nrow = new.n, ncol = nCause)
        M.etimes.max <- matrix(NA, nrow = new.n, ncol = nCause)
        
        for(iterC in 1:nCause){
          infoVar <- coxVariableName(object$models[[iterC]])

          if(iterC == index.cause || product.limit || se || iid || average.iid){            
              typeC <- c("hazard","cumhazard")
          }else{
              typeC <- "cumhazard"
          }
          baseline <- predictCox(object$models[[iterC]], centered = FALSE,
                                 times = eventTimes, newdata = NULL,
                                 type = typeC, 
                                 keep.strata = TRUE, keep.times = TRUE,
                                 se = FALSE)
          
          ## baseline hazard from the Cox model
          ls.cumhazard[[iterC]] <- matrix(baseline$cumhazard, byrow = FALSE, nrow = nEventTimes)
          if("hazard" %in% typeC){            
              ls.hazard[[iterC]] <- matrix(baseline$hazard, byrow = FALSE, nrow = nEventTimes)
          }else{
              ls.hazard[[iterC]] <- matrix()
          }
          
          ## linear predictor for the new observations
          M.eXb[,iterC] <- exp(coxLP(object$models[[iterC]], data = newdata, center = FALSE))
          
          ## strata for the new observations
          M.strata[,iterC] <- as.numeric(coxStrata(object$models[[iterC]], data = newdata, 
                                                   sterms = infoVar$sterms, 
                                                   strata.vars = infoVar$strata.vars, 
                                                   levels = levels(baseline$strata), 
                                                   strata.levels = infoVar$strata.levels))-1
          
          ## last time by strata
          M.etimes.max[,iterC] <- baseline$lastEventTime[M.strata[,iterC]+1]
        }
        
        
    }else if (surv.type == "survival"){
        
        #### cause ####
        
        ## baseline hazard from the Cox model
        baseline_Cause <- predictCox(object$models[[paste("Cause",cause)]],
                                     centered = FALSE,
                                     times = eventTimes,
                                     newdata = NULL,
                                     type = c("hazard","cumhazard"),
                                     keep.strata = TRUE,
                                     keep.times = TRUE,
                                     se = FALSE)

        
        ## linear predictor for the new observations
        eXb_Cause <- cbind(exp(coxLP(object$models[[paste("Cause",cause)]], data = newdata, center = FALSE)))
        
        ## strata for the new observations
        infoVar_Cause <- coxVariableName(object$models[[paste("Cause",cause)]])
        strata_Cause <- coxStrata(object$models[[paste("Cause",cause)]],
                                  data = newdata,
                                  sterms = infoVar_Cause$sterms,
                                  strata.vars = infoVar_Cause$strata.vars,
                                  levels = levels(baseline_Cause$strata),
                                  strata.levels = infoVar_Cause$strata.levels)
        
        
        #### overall ####

        ### baseline hazard from the Cox model
        baseline_Overall <- predictCox(object$models[["OverallSurvival"]], centered = FALSE,
                                       times = eventTimes, newdata = NULL,
                                       type = c("hazard","cumhazard"), 
                                       keep.strata = TRUE, keep.times = TRUE,
                                       se = FALSE)
        
        ## linear predictor for the new observations
        eXb_Overall <- cbind(exp(coxLP(object$models[["OverallSurvival"]], data = newdata, center = FALSE)))
        ## strata for the new observations
        infoVar_Overall <- coxVariableName(object$models[["OverallSurvival"]])
        strata_Overall <- coxStrata(object$models[["OverallSurvival"]],
                                  data = newdata,
                                  sterms = infoVar_Overall$sterms,
                                  strata.vars = infoVar_Overall$strata.vars,
                                  levels = levels(baseline_Overall$strata),
                                  strata.levels = infoVar_Overall$strata.levels)
        
        
        #### store
        ls.hazard <- list(matrix(baseline_Cause$hazard, byrow = FALSE, nrow = nEventTimes),# for predictCIF_cpp
                          matrix(baseline_Overall$hazard, byrow = FALSE, nrow = nEventTimes)) # for predictCIF_cpp
        ls.cumhazard <- list(matrix(baseline_Cause$cumhazard, byrow = FALSE, nrow = nEventTimes), # for calcSeCSC
                             matrix(baseline_Overall$cumhazard, byrow = FALSE, nrow = nEventTimes))
        M.eXb <- cbind(eXb_Cause, eXb_Overall)
        M.strata <- cbind(as.numeric(strata_Cause)-1,
                          as.numeric(strata_Overall)-1)
        M.etimes.max <- cbind(baseline_Cause$lastEventTime[M.strata[,1]+1]) # last time by strata
    }

    CIF <- predictCIF_cpp(hazard = ls.hazard, 
                          cumhazard = ls.cumhazard, 
                          eXb = M.eXb, 
                          strata = M.strata,
                          newtimes = sort(times), 
                          etimes = eventTimes, 
                          etimeMax = apply(M.etimes.max,1,min), 
                          t0 = landmark,
                          nEventTimes = nEventTimes,
                          nNewTimes = length(times), 
                          nData = new.n,
                          cause = index.cause - 1, 
                          nCause = nCause,
                          survtype = (surv.type=="survival"),
                          productLimit = product.limit)
    
    #### standard error ####
    if(se || iid || average.iid){
        if(!is.na(landmark)){
            stop("standard error for the conditional survival not implemented \n")
        }

        ## design matrix
        new.LPdata <- list()
        for(iCause in 1:nCause){
            infoVar <- coxVariableName(object$models[[iCause]])
            
            if(length(infoVar$lpvars) > 0){
                new.LPdata[[iCause]] <- model.matrix(object$models[[iCause]], newdata)
            }else{
                new.LPdata[[iCause]] <- matrix(0, ncol = 1, nrow = new.n)
            }  
        }


        nVar <- unlist(lapply(object$models,function(m){
            length(coxVariableName(m)$lpvars)
        }))

        out.seCSC <- calcSeCSC(object,
                               cif = CIF,
                               hazard = ls.hazard,
                               cumhazard = ls.cumhazard,
                               object.time = eventTimes,
                               object.maxtime = apply(M.etimes.max,1,min), 
                               eXb = M.eXb,
                               new.LPdata = new.LPdata,
                               new.strata = M.strata,                               
                               times = sort(times),
                               new.n = new.n,
                               cause = which(causes == cause),
                               nCause = nCause,
                               nVar = nVar,
                               surv.type = surv.type,
                               log.transform = log.transform,
                               export = c("iid"[iid==TRUE],"se"[se==TRUE],"average.iid"[average.iid==TRUE]),
                               store.iid = store.iid)
    }
    
    #### export ####
    out <- list(absRisk = CIF[,ootimes,drop=FALSE]) # reorder prediction times

    if(se){
        out$absRisk.se <- out.seCSC$se[,ootimes,drop=FALSE]
        zval <- qnorm(1-(1-conf.level)/2, 0,1)

        if(log.transform){
            out$absRisk.lower <- exp(-exp(log(-log(out$absRisk)) + zval*out$absRisk.se))
            out$absRisk.upper <- exp(-exp(log(-log(out$absRisk)) - zval*out$absRisk.se))
        }else{            
            # to keep matrix format even when out$absRisk contains only one line
            out$absRisk.lower <- out$absRisk.upper <- matrix(NA, nrow = NROW(out$absRisk.se), ncol = NCOL(out$absRisk.se))
            out$absRisk.lower[] <- apply(out$absRisk - zval*out$absRisk.se,2,pmax,0)
            out$absRisk.upper[] <- apply(out$absRisk + zval*out$absRisk.se,2,pmin,1)
        }
    }
    if(iid){
        out$absRisk.iid <- out.seCSC$iid[,ootimes,,drop=FALSE]
    }
    if(average.iid){
        out$absRisk.average.iid <- out.seCSC$average.iid[,ootimes,drop=FALSE]
    }
    if(band>0){
        
        out$quantile.band <- confBandCox(iid = out$absRisk.iid,
                                         se = out$absRisk.se,
                                         n.sim = nsim.band,
                                         conf.level = conf.level)
            
        if(iid.save==FALSE){
            out$absRisk.iid <- NULL
        }

        quantile95 <- colMultiply_cpp(out$absRisk.se,out$quantile.band)
                
        if(log.transform){
            out$absRisk.lowerBand <- exp(-exp(log(-log(out$absRisk)) + quantile95))
            out$absRisk.upperBand <- exp(-exp(log(-log(out$absRisk)) - quantile95))
        }else{            
            out$absRisk.lowerBand <- matrix(NA, nrow = NROW(out$absRisk.se), ncol = NCOL(out$absRisk.se))
            out$absRisk.lowerBand[] <- apply(out$absRisk - quantile95,2,pmax,0)
            out$absRisk.upperBand <- out$absRisk + quantile95
        }
        
        if(se.save==FALSE){
            out$absRisk.se <- NULL
            out$absRisk.lower <- NULL
            out$absRisk.upper <- NULL
        }
    }    
    if(keep.times){out$times <- times}
    if(keep.newdata==TRUE){
        allVars <- unique(unlist(lapply(object$models, function(m){coxCovars(m)})))
        if(length(allVars)>0){
            out$newdata <- newdata[, allVars, with = FALSE]
        }
    }
    if(keep.strata==TRUE){
        allStrata <- unique(unlist(lapply(object$models, function(m){coxVariableName(m)$strata.vars.original})))
        if (length(allStrata)>0){
            newdata <- copy(newdata[,allStrata, with = FALSE])
            newdata[, (allStrata) := lapply(allStrata, function(col){paste0(col,"=",.SD[[col]])})]
            out$strata <- newdata[, interaction(.SD, sep = " "), .SDcols = allStrata]
        }
    }
    out$conf.level <- conf.level
    transformation.absRisk <- if(log.transform){function(x){log(-log(1-x))}}else{NA}
    out <- c(out,list(se = se.save, band = band, nsim.band = nsim.band, transformation.absRisk = transformation.absRisk))
    class(out) <- "predictCSC"
    return(out)
}



