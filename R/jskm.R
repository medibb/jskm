
#' @title Creates a Kaplan-Meier plot for survfit object.
#' @description Creates a Kaplan-Meier plot with at risk tables below for survfit object.
#' @param sfit a survfit object
#' @param table logical: Create a table graphic below the K-M plot, indicating at-risk numbers?
#' @param xlabs x-axis label
#' @param ylabs y-axis label
#' @param xlims numeric: list of min and max for x-axis. Default = c(0,max(sfit$time))
#' @param ylims numeric: list of min and max for y-axis. Default = c(0,1)
#' @param surv.scale 	scale transformation of survival curves. Allowed values are "default" or "percent".
#' @param ystratalabs character list. A list of names for each strata. Default = names(sfit$strata)
#' @param ystrataname The legend name. Default = "Strata"
#' @param timeby numeric: control the granularity along the time-axis; defaults to 7 time-points. Default = signif(max(sfit$time)/7, 1)
#' @param main plot title
#' @param pval logical: add the pvalue to the plot?
#' @param pval.size numeric value specifying the p-value text size. Default is 5.
#' @param pval.coord numeric vector, of length 2, specifying the x and y coordinates of the p-value. Default values are NULL
#' @param pval.testname logical: add '(Log-rank)' text to p-value. Default = F
#' @param marks logical: should censoring marks be added?
#' @param shape what shape should the censoring marks be, default is a vertical line
#' @param legend logical. should a legend be added to the plot?
#' @param legendposition numeric. x, y position of the legend if plotted. Default=c(0.85,0.8)
#' @param ci logical. Should confidence intervals be plotted. Default = FALSE
#' @param subs = NULL,
#' @param label.nrisk Numbers at risk label. Default = "Numbers at risk"
#' @param size.label.nrisk Font size of label.nrisk. Default = 10
#' @param linecols Character. Colour brewer pallettes too colour lines. Default ="Set1",
#' @param dashed logical. Should a variety of linetypes be used to identify lines. Default = FALSE
#' @param cumhaz Show cumulaive hazard function, Default: F
#' @param cluster.option Cluster option for p value, Option: "None", "cluster", "frailty", Default: "None"
#' @param cluster.var Cluster variable
#' @param data select specific data - for reactive input. Default = NULL
#' @param ... PARAM_DESCRIPTION
#' @return Plot
#' @details DETAILS
#' @author Jinseob Kim, but heavily modified version of a script created by Michael Way.
#' \url{https://github.com/michaelway/ggkm/}
#' I have packaged this function, added functions to namespace and included a range of new parameters.
#' @examples
#'  library(survival)
#'  data(colon)
#'  fit <- survfit(Surv(time,status)~rx, data=colon)
#'  jskm(fit, timeby=500)
#' @rdname jskm
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 geom_step
#' @importFrom ggplot2 scale_linetype_manual
#' @importFrom ggplot2 scale_colour_manual
#' @importFrom ggplot2 theme_bw
#' @importFrom ggplot2 theme
#' @importFrom ggplot2 element_text
#' @importFrom ggplot2 scale_x_continuous
#' @importFrom ggplot2 scale_y_continuous
#' @importFrom ggplot2 element_blank
#' @importFrom ggplot2 element_line
#' @importFrom ggplot2 element_rect
#' @importFrom ggplot2 labs
#' @importFrom ggplot2 ggtitle
#' @importFrom ggplot2 geom_point
#' @importFrom ggplot2 geom_blank
#' @importFrom ggplot2 annotate
#' @importFrom ggplot2 geom_text
#' @importFrom ggplot2 scale_y_discrete
#' @importFrom ggplot2 xlab
#' @importFrom ggplot2 ylab
#' @importFrom ggplot2 ggsave
#' @importFrom ggplot2 scale_colour_brewer
#' @importFrom ggplot2 geom_ribbon
#' @importFrom grid unit
#' @importFrom gridExtra grid.arrange
#' @importFrom plyr rbind.fill
#' @importFrom stats pchisq time as.formula
#' @importFrom survival survfit survdiff coxph Surv cluster frailty
#' @export
 

jskm <- function(sfit,
                 table = FALSE,
                 xlabs = "Time-to-event",
                 ylabs = "Survival probability",
                 xlims = c(0,max(sfit$time)),
                 ylims = c(0,1),
                 surv.scale = c("default", "percent"),
                 ystratalabs = names(sfit$strata),
                 ystrataname = "Strata",
                 timeby = signif(max(sfit$time)/7, 1),
                 main = "",
                 pval = FALSE,
                 pval.size = 5, 
                 pval.coord = c(NULL, NULL),
                 pval.testname = F,
                 marks = TRUE,
                 shape = 3,
                 legend = TRUE,
                 legendposition=c(0.85,0.8),
                 ci = FALSE,
                 subs = NULL,
                 label.nrisk = "Numbers at risk",
                 size.label.nrisk = 10,
                 linecols="Set1",
                 dashed= FALSE,
                 cumhaz = F,
                 cluster.option = "None",
                 cluster.var = NULL,
                 data = NULL,
                 ...) {
  
  
  #################################
  # sorting the use of subsetting #
  #################################
  
  n.risk <- n.censor <- surv <- strata <- lower <- upper <- NULL
  
  times <- seq(0, max(sfit$time), by = timeby)
  
  if(is.null(subs)){
    if(length(levels(summary(sfit)$strata)) == 0) {
      subs1 <- 1
      subs2 <- 1:length(summary(sfit,censored=T)$time)
      subs3 <- 1:length(summary(sfit,times = times,extend = TRUE)$time)
    } else {
      subs1 <- 1:length(levels(summary(sfit)$strata))
      subs2 <- 1:length(summary(sfit,censored=T)$strata)
      subs3 <- 1:length(summary(sfit,times = times,extend = TRUE)$strata)
    }
  } else{
    for(i in 1:length(subs)){
      if(i==1){
        ssvar <- paste("(?=.*\\b=",subs[i],sep="")
      }
      if(i==length(subs)){
        ssvar <- paste(ssvar,"\\b)(?=.*\\b=",subs[i],"\\b)",sep="")
      }
      if(!i %in% c(1, length(subs))){
        ssvar <- paste(ssvar,"\\b)(?=.*\\b=",subs[i],sep="")
      }
      if(i==1 & i==length(subs)){
        ssvar <- paste("(?=.*\\b=",subs[i],"\\b)",sep="")
      }
    }
    subs1 <- which(regexpr(ssvar,levels(summary(sfit)$strata), perl=T)!=-1)
    subs2 <- which(regexpr(ssvar,summary(sfit,censored=T)$strata, perl=T)!=-1)
    subs3 <- which(regexpr(ssvar,summary(sfit,times = times,extend = TRUE)$strata, perl=T)!=-1)
  }
  
  if(!is.null(subs)) pval <- FALSE
  
  ##################################
  # data manipulation pre-plotting #
  ##################################
  
  
  
  if(length(levels(summary(sfit)$strata)) == 0) {
    #[subs1]
    if(is.null(ystratalabs)) ystratalabs <- as.character(sub("group=*","","All"))
  } else {
    #[subs1]
    if(is.null(ystratalabs)) ystratalabs <- as.character(sub("group=*","",names(sfit$strata)))
  }
  
  if(is.null(ystrataname)) ystrataname <- "Strata"
  m <- max(nchar(ystratalabs))
  times <- seq(0, max(sfit$time), by = timeby)
  
  if(length(levels(summary(sfit)$strata)) == 0) {
    Factor <- factor(rep("All",length(subs2)))
  } else {
    Factor <- factor(summary(sfit, censored = T)$strata[subs2])
  }
  
  #Data to be used in the survival plot
  
  df <- data.frame(
    time = sfit$time[subs2],
    n.risk = sfit$n.risk[subs2],
    n.event = sfit$n.event[subs2],
    n.censor = sfit$n.censor[subs2],
    surv = sfit$surv[subs2],
    strata = Factor,
    upper = sfit$upper[subs2],
    lower = sfit$lower[subs2]
  )
  
  if (cumhaz){
    df$surv = 1 - sfit$surv[subs2]
    df$lower = 1 - sfit$upper[subs2]
    df$upper = 1 - sfit$lower[subs2]
    
  }
  
  #Final changes to data for survival plot
  levels(df$strata) <- ystratalabs
  zeros <- data.frame(time = 0, surv = 1,
                      strata = factor(ystratalabs, levels=levels(df$strata)),
                      upper = 1, lower = 1)
  if (cumhaz){
    zeros$surv = 0
    zeros$lower = 0
    zeros$upper = 0
  }
  
  df <- plyr::rbind.fill(zeros, df)
  d <- length(levels(df$strata))
  
  ###################################
  # specifying axis parameteres etc #
  ###################################
  
  if(dashed == TRUE){
    linetype=c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash", "1F", "F1", "4C88C488", "12345678")
  } else {
    linetype=c("solid", "solid", "solid", "solid", "solid", "solid", "solid", "solid", "solid", "solid", "solid")
  }
  
  # Scale transformation
  #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  surv.scale <- match.arg(surv.scale)
  scale_labels <-  ggplot2::waiver()
  if (surv.scale == "percent") scale_labels <- scales::percent
  
  p <- ggplot2::ggplot( df, aes(x=time, y=surv, colour=strata, linetype=strata)) + ggtitle(main)
  
  #Set up theme elements
  p <- p + theme_bw() +
    theme(axis.title.x = element_text(vjust = 0.7),
          panel.grid.minor = element_blank(),
          axis.line = element_line(size =0.5, colour = "black"),
          legend.position = legendposition,
          legend.background = element_rect(fill = NULL),
          legend.key = element_rect(colour = NA),
          panel.border = element_blank(),
          plot.margin = unit(c(0, 1, .5,ifelse(m < 10, 1.5, 2.5)),"lines"),
          panel.grid.major = element_blank(),
          axis.line.x = element_line(size = 0.5, linetype = "solid", colour = "black"),
          axis.line.y = element_line(size = 0.5, linetype = "solid", colour = "black")) +
    scale_x_continuous(xlabs, breaks = times, limits = xlims) +
    scale_y_continuous(ylabs, limits = ylims, labels = scale_labels)
  
  
  #Add 95% CI to plot
  if(ci == TRUE)
    p <- p +  geom_ribbon(data=df, aes(ymin = lower, ymax = upper), fill = "grey", alpha=0.25, colour=NA)
  
  #Removes the legend:
  if(legend == FALSE)
    p <- p + theme(legend.position="none")
  
  #Add lines too plot
  p <- p + geom_step(size = 0.75) +
    scale_linetype_manual(name = ystrataname, values=linetype) +
    scale_colour_brewer(name = ystrataname, palette=linecols)
  
  #Add censoring marks to the line:
  if(marks == TRUE)
    p <- p + geom_point(data = subset(df, n.censor >= 1), aes(x = time, y = surv), shape = shape, colour = "black")
  
  
  
  ## Create a blank plot for place-holding
  blank.pic <- ggplot(df, aes(time, surv)) +
    geom_blank() + theme_void() +             ## Remove gray color
    theme(axis.text.x = element_blank(),axis.text.y = element_blank(),
          axis.title.x = element_blank(),axis.title.y = element_blank(),
          axis.ticks = element_blank(),
          panel.grid.major = element_blank(),panel.border = element_blank())
  
  #####################
  # p-value placement #
  #####################a
  
  if(length(levels(summary(sfit)$strata)) == 0) pval <- FALSE
  
  if(pval == TRUE) {
    if (is.null(data)){
      data = eval(sfit$call$data)
    }
  
    sdiff <- survival::survdiff(as.formula(sfit$call$formula), data = data)
    pvalue <- pchisq(sdiff$chisq,length(sdiff$n) - 1,lower.tail = FALSE)
    
    ## cluster option
    if (cluster.option == "cluster" & !is.null(cluster.var)){
      form.old = as.character(sfit$call$formula)
      form.new = paste(form.old[2], form.old[1], " + ", form.old[3], " + cluster(", cluster.var, ")", sep="")
      sdiff <- survival::coxph(as.formula(form.new), data = data, model = T)
      pvalue <- summary(sdiff)$robscore["pvalue"]
    } else if (cluster.option == "frailty" & !is.null(cluster.var)){
      form.old = as.character(sfit$call$formula)
      form.new = paste(form.old[2], form.old[1], " + ", form.old[3], " + frailty(", cluster.var, ")", sep="")
      sdiff <- survival::coxph(as.formula(form.new), data =data, model = T)
      pvalue <- summary(sdiff)$logtest["pvalue"]
    }
    
    pvaltxt <- ifelse(pvalue < 0.0001,"p < 0.0001",paste("p =", round(pvalue, 3)))
    
    if (pval.testname) pvaltxt <- paste0(pvaltxt, " (Log-rank)")
    
    # MOVE P-VALUE LEGEND HERE BELOW [set x and y]
    if (is.null(pval.coord)){
      p <- p + annotate("text",x = (as.integer(max(sfit$time)/5)), y = 0.1 + ylims[1],label = pvaltxt, size  = pval.size)
    } else{
      p <- p + annotate("text",x = pval.coord[1], y = pval.coord[2], label = pvaltxt, size  = pval.size)
    }
    
  }
  
  ###################################################
  # Create table graphic to include at-risk numbers #
  ###################################################
  
  n.risk <- NULL
  if(length(levels(summary(sfit)$strata)) == 0) {
    Factor <- factor(rep("All",length(subs3)))
  } else {
    Factor <- factor(summary(sfit,times = times,extend = TRUE)$strata[subs3])
  }
  
  if(table == TRUE) {
    risk.data <- data.frame(
      strata = Factor,
      time = summary(sfit,times = times,extend = TRUE)$time[subs3],
      n.risk = summary(sfit,times = times,extend = TRUE)$n.risk[subs3]
    )
    
    risk.data$strata <- factor(risk.data$strata, levels=rev(levels(risk.data$strata)))
    
    data.table <- ggplot(risk.data,aes(x = time, y = strata, label = format(n.risk, nsmall = 0))) + 
      geom_text(size = 3.5) + theme_bw() +
      scale_y_discrete(breaks = as.character(levels(risk.data$strata)),
                       labels = rev(ystratalabs)) +
      scale_x_continuous(label.nrisk, limits = xlims) +
      theme(axis.title.x = element_text(size = size.label.nrisk, vjust = 1),
            panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            panel.border = element_blank(),axis.text.x = element_blank(),
            axis.ticks = element_blank(),axis.text.y = element_text(face = "bold",hjust = 1)) 
    data.table <- data.table +
      theme(legend.position = "none") + xlab(NULL) + ylab(NULL)
    
    
    # ADJUST POSITION OF TABLE FOR AT RISK
    data.table <- data.table +
      theme(plot.margin = unit(c(-1.5, 1, 0.1, ifelse(m < 10, 2.5, 3.5) - 0.15 * m), "lines"))
  }
  
  
  #######################
  # Plotting the graphs #
  #######################
  
  if(table == TRUE){
    grid.arrange(p, blank.pic, data.table, clip = FALSE, nrow = 3,
                 ncol = 1, heights = unit(c(2, .1, .25),c("null", "null", "null")))
  } else {
    p
  }
  
}
