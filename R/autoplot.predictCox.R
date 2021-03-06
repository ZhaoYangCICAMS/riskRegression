### autoplot.predictCox.R --- 
#----------------------------------------------------------------------
## author: Brice Ozenne
## created: feb 17 2017 (10:06) 
## Version: 
## last-updated: okt  3 2017 (17:21) 
##           By: Brice Ozenne
##     Update #: 332
#----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
#----------------------------------------------------------------------
## 
### Code:

# {{{ autoplot.predictCox
#' @title Plot predictions from a Cox model
#' @description Plot predictions from a Cox model
#' 
#' @param object object obtained with the function \code{predictCox}.
#' @param type the type of predicted value to display. Choices are 
#' \code{"hazard"} the hazard function,
#' \code{"cumhazard"} the cumulative hazard function, 
#' or \code{"survival"} the survival function.
#' @param ci Logical. If \code{TRUE} display the confidence intervals for the predictions.
#' @param band Logical. If \code{TRUE} display the confidence bands for the predictions.
#' @param group.by The grouping factor used to color the prediction curves. Can be \code{"row"}, \code{"strata"}, or \code{"covariates"}.
#' @param reduce.data Logical. If \code{TRUE} only the covariates that does take indentical values for all observations are displayed.
#' @param plot Logical. Should the graphic be plotted.
#' @param digits integer indicating the number of decimal places
#' @param alpha transparency of the confidence bands. Argument passed to \code{ggplot2::geom_ribbon}.
#' @param ... not used. Only for compatibility with the plot method.
#' 
#' @examples
#' library(survival)
#' library(ggplot2)
#'
#' ## predictions ##
#' d <- sampleData(1e2, outcome = "survival")
#' m.cox <- coxph(Surv(time,event)~ X1 + X2 + X3,
#'                 data = d, x = TRUE, y = TRUE)
#' dt.basehaz <- predictCox(m.cox)
#' ggplot(as.data.table(dt.basehaz), aes(x = time, y = survival)) + geom_point() + geom_line()
#'
#' pred.cox <- predictCox(m.cox, newdata = d[1:4,],
#'   times = 1:5, type = "survival", keep.newdata = TRUE)
#' autoplot(pred.cox)
#' autoplot(pred.cox, group.by = "covariates")
#' autoplot(pred.cox, group.by = "covariates", reduce.data = TRUE)
#' 
#' 
#' m.cox.strata <- coxph(Surv(time,event)~ strata(X1) + strata(X2) + X3 + X6,
#' data = d, x = TRUE, y = TRUE)
#' pred.cox.strata <- predictCox(m.cox.strata, newdata = d[1,,drop=FALSE],
#' time = 1:5, keep.newdata = TRUE)
#' autoplot(pred.cox.strata, type = "survival")
#' autoplot(pred.cox.strata, type = "survival", group.by = "strata")
#' res <- autoplot(pred.cox.strata, type = "survival",
#'             group.by = "covariates")
#'
#' # customize display
#' res$plot + geom_point(data = res$data, size = 5)
#'
#' ## predictions with confidence interval
#' pred.cox <- predictCox(m.cox, newdata = d[1,,drop=FALSE],
#'   times = 1:5, type = "survival", se = TRUE, keep.newdata = TRUE)
#' autoplot(pred.cox, ci = TRUE)
#'
#' ## predictions with confidence bands
#' pred.cox <- predictCox(m.cox, newdata = d[1,,drop=FALSE],
#'   times = 1:5, type = "survival", nsim.band = 500,  band = TRUE, keep.newdata = TRUE)
#' autoplot(pred.cox, band = TRUE)
#'
#' 
#' @method autoplot predictCox
#' @export
autoplot.predictCox <- function(object,
                            type = NULL,
                            ci = FALSE,
                            band = FALSE,
                            group.by = "row",
                            reduce.data = FALSE,
                            plot = TRUE,
                            digits = 2, alpha = NA, ...){
  
  ## initialize and check    
  possibleType <- c("hazard","cumhazard","survival")
  possibleType <- possibleType[possibleType %in% names(object)]

  if(is.null(type)){
    if(length(possibleType) == 1){
      type <- possibleType
    }else{
      stop("argument \'type\' must be specified to choose between ",paste(possibleType, collapse = " "),"\n")
    }
  }else{
    type <- match.arg(type, possibleType)  
  } 
  typename <- switch(type,
                     hazard = "hazard",
                     cumhazard = "cumulative hazard",
                     survival = "survival")
  
  group.by <- match.arg(group.by, c("row","covariates","strata"))
 
  
  if(group.by == "covariates" && ("newdata" %in% names(object) == FALSE)){
    stop("argument \'group.by\' cannot be \"covariates\" when newdata is missing in the object \n",
         "set argment \'keep.newdata\' to TRUE when calling predictCox \n")
  }
  if(group.by == "strata" && ("strata" %in% names(object) == FALSE)){
    stop("argument \'group.by\' cannot be \"strata\" when strata is missing in the object \n",
         "set argment \'keep.strata\' to TRUE when calling predictCox \n")
  }
  
  if(ci && (paste0(type,".se") %in% names(object) == FALSE)){
    stop("argument \'ci\' cannot be TRUE when no standard error have been computed \n",
         "set argment \'se\' to TRUE when calling predictCox \n")
  }

    if(ci && object$se == FALSE){
        stop("argument \'ci\' cannot be TRUE when no standard error have been computed \n",
             "set argment \'se\' to TRUE when calling predictCox \n")
    }

    if(band && object$band == FALSE){
        stop("argument \'band\' cannot be TRUE when no quantiles for the confidence bands have not been computed \n",
             "set argment \'nsim.band\' to a positive integer when calling predictCox \n")
    }
    
    ## display
    newdata <- copy(object$newdata)
    if(!is.null(newdata) && reduce.data){
        test <- unlist(newdata[,lapply(.SD, function(col){length(unique(col))==1})])
        if(any(test)){
            newdata[, (names(test)[test]):=NULL]
        }        
    }

    dataL <- predict2melt(outcome = object[[type]], ci = ci, band = band,
                          outcome.lower = if(ci){object[[paste0(type,".lower")]]}else{NULL},
                          outcome.upper = if(ci){object[[paste0(type,".upper")]]}else{NULL},
                          outcome.lowerBand = if(band){object[[paste0(type,".lowerBand")]]}else{NULL},
                          outcome.upperBand = if(band){object[[paste0(type,".upperBand")]]}else{NULL},
                          newdata = newdata,
                          strata = object$strata,
                          times = object$times,
                          name.outcome = typename,
                          group.by = group.by,
                          digits = digits
                          )

    gg.res <- predict2plot(dataL = dataL,
                           name.outcome = typename,
                           ci = ci,
                           band = band,
                           group.by = group.by,
                           conf.level = object$conf.level,
                           alpha = alpha,
                           origin = min(object$times)
                           )
  
  if(plot){
    print(gg.res$plot)
  }
  
  return(invisible(gg.res))
}
# }}}

# {{{ predict2melt
predict2melt <- function(outcome, name.outcome,
                         ci, outcome.lower, outcome.upper,
                         band, outcome.lowerBand, outcome.upperBand,
                         newdata, strata, times, group.by, digits){

    ## for CRAN tests
    patterns <- function(){}
    
    n.time <- NCOL(outcome)
    if(!is.null(time)){
        time.names <- times 
    }else{
        time.names <- 1:n.time
    }    
    colnames(outcome) <- paste0(name.outcome,"_",time.names)
    keep.cols <- unique(c("time",name.outcome,"row",group.by))
    
    #### merge outcome with CI and band ####
    pattern <- paste0(name.outcome,"_")
    if(ci){
        pattern <- c(pattern,"lowerCI_","upperCI_")
    
        colnames(outcome.lower) <- paste0("lowerCI_",time.names)
        colnames(outcome.upper) <- paste0("upperCI_",time.names)
    }
    if(band){
        pattern <- c(pattern,"lowerBand_","upperBand_")
        keep.cols <- c(keep.cols,"lowerBand","upperBand")
        
        colnames(outcome.lowerBand) <- paste0("lowerBand_",time.names)
        colnames(outcome.upperBand) <- paste0("upperBand_",time.names)
    }

    outcome <- data.table::as.data.table(
                               cbind(outcome,
                                     outcome.lower, outcome.upper,
                                     outcome.lowerBand,outcome.upperBand)
                           )

    #### merge with convariates ####
    outcome[, row := 1:.N]
    if(group.by == "covariates"){
        cov.names <- names(newdata)
        newdata <- newdata[, (cov.names) := lapply(cov.names, function(col){paste0(col,"=",round(.SD[[col]],digits))})]
        outcome[, ("covariates") := interaction(newdata,sep = " ")]
    }else if(group.by == "strata"){
        outcome[, strata := strata]
    }
    
    #### reshape to long format ####
    dataL <- melt(outcome, id.vars = union("row",group.by),
                   measure= patterns(pattern),
                   variable.name = "time", value.name = gsub("_","",pattern))
    dataL[, time := as.numeric(as.character(factor(time, labels = time.names)))]

    return(dataL)    
}

# }}}
# {{{ predict2plot
predict2plot <- function(dataL, name.outcome,
                         ci, band, group.by,                         
                         conf.level, alpha, origin){

    # for CRAN tests
    original <- lowerCI <- upperCI <- lowerBand <- upperBand <- NULL
    #### duplicate observations to obtain step curves ####
    keep.cols <- unique(c("time",name.outcome,"row",group.by,"original"))
    if(ci){
        keep.cols <- c(keep.cols,"lowerCI","upperCI")
    }
    if(band){
        keep.cols <- c(keep.cols,"lowerBand","upperBand")
    }
    dataL[, original := TRUE]

    dtTempo <- copy(dataL)
    dtTempo[, (c("time","original")) := list(time = c(origin,.SD$time[-.N] + .Machine$double.eps*100),
                                             original = FALSE),
            by = row]

    dataL <- rbind(dataL[,unique(keep.cols), with = FALSE],
                   dtTempo[,unique(keep.cols), with = FALSE])
    
    #### display ####
    labelCI <- paste0(conf.level*100,"% confidence \n interval")
    labelBand <- paste0(conf.level*100,"% confidence \n band")

    gg.base <- ggplot(mapping = aes_string(x = "time", y = name.outcome, group = "row", color = group.by))
    gg.base <- gg.base + geom_line(data = dataL, size = 2)
    if(group.by=="row"){
        gg.base <- gg.base + ggplot2::labs(color="observation") + theme(legend.key.height=unit(0.1,"npc"),
                                                                        legend.key.width=unit(0.08,"npc"))
        
        # display only integer values
        uniqueObs <- unique(dataL$row)

        if(length(uniqueObs)==1){
            gg.base <- gg.base + scale_color_continuous(guide=FALSE)
        }else{
            gg.base <- gg.base + scale_color_continuous(breaks = uniqueObs[seq(1,length(uniqueObs), length.out = min(10,length(uniqueObs)))],
                                                        limits = c(0.5, length(uniqueObs) + 0.5))
        }
    }
    if(ci){
        if(!is.na(alpha)){
            gg.base <- gg.base + geom_errorbar(data = dataL[original==TRUE],
                                               aes(ymin = lowerCI, ymax = upperCI, linetype = labelCI))
            gg.base <- gg.base + scale_linetype_manual("",values=setNames(1,labelCI))

        }else{
            gg.base <- gg.base + geom_line(data = dataL, aes(y = lowerCI, linetype = "ci"), size = 1.2, color = "black")
            gg.base <- gg.base + geom_line(data = dataL, aes(y = upperCI, linetype = "ci"), size = 1.2, color = "black")
#            gg.base <- gg.base + geom_ribbon(data = dataL, aes(ymin = lowerCI, ymax = upperCI, linetype = "ci") , fill = NA, color = "black")
        }
    }
    if(band){
        if(!is.na(alpha)){
            gg.base <- gg.base + geom_ribbon(data = dataL,
                                             aes(ymin = lowerBand, ymax = upperBand, fill = labelBand),
                                             alpha = alpha)
            gg.base <- gg.base + scale_fill_manual("", values="grey12")        
        }else{
            gg.base <- gg.base + geom_line(data = dataL, aes(y = lowerBand, linetype = "band"), size = 1.2, color = "black")
            gg.base <- gg.base + geom_line(data = dataL, aes(y = upperBand, linetype = "band"), size = 1.2, color = "black")
        }
    }

    if(is.na(alpha) && (band || ci)){
        indexTempo <- which(c(ci,band)==1)
        if(band && ci){
            value <- c(1,2)
        }else{
            value <- 1
        }
        gg.base <- gg.base + scale_linetype_manual("", breaks = c("ci","band")[indexTempo],
                                                   labels = c(labelCI,labelBand)[indexTempo],
                                                   values = value)
    }else if(ci && band){
        gg.base <- gg.base + ggplot2::guides(linetype = ggplot2::guide_legend(order = 1),
                                             fill = ggplot2::guide_legend(order = 2),
                                             group = ggplot2::guide_legend(order = 3)
                                             )
    }
    
    ## export
    ls.export <- list(plot = gg.base,
                      data = dataL)
    
    return(ls.export)
}
# }}}

#----------------------------------------------------------------------
### autoplot.predictCox.R ends here
