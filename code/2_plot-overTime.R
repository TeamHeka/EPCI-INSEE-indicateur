

plotPropTime <- function(out, plotDates = FALSE, plotGraduations = FALSE){
  # out table of results, with parameter values
  
  # Define color palette
  nn <- 1/unique(out$by.prbs) # Number of categories to plot
  palCat <- rev(met.brewer("Hiroshige", nn, type = "continuous"))
  names(palCat) <- 1:nn

  mnths <- seq(as.Date(min(out$thedate)), as.Date(max(out$thedate)), by = "month")
  
  # For each variable
  for(varPred in unique(out$varPred)){
    # Initialize plot
    par(mar = c(3, 4, 2, 2), mgp = c(1.75, 0.25, 0), las = 1, tck = - 0.01)
    plot(0, xlim = range(as.Date(dates)), ylim = c(0, 1), axes = FALSE, 
         xlab = "date", ylab = "Adjusted vaccination rate", yaxs = "i", xaxs = "i", 
         main = varPred)
    axis(1, at = mnths, labels = format(mnths, "%b"))
    axis(2)
    axis(4)
    
    if(plotGraduations){
      for(i in seq(0, 1, by = 0.1)){
        par(xpd = FALSE)
        abline(h = i, col = gray(0.8))
      }
    }
    
    # Subset of the data for this predictor
    sub <- out[out$varPred == varPred, ]
    
    # Plot the predicted values
    for(i in 1:nn){
      lines(as.Date(sub$thedate), sub[, paste0("V", i)], col = palCat[i], lwd = 2)
    }
    
    # Show dates
    if(plotDates){
      par(xpd = FALSE)
      abline(v = as.Date(date.SP.announcement), lty = 2)
      abline(v = as.Date(date.SP.implementation))
      
      abline(v = as.Date(date.VP.announcement), lty = 2)
      abline(v = as.Date(date.VP.implementation))
      
      par(xpd = TRUE)
      yt <- 0.05
      cext <- 0.75
      text(x = c(as.Date(date.SP.announcement), as.Date(date.VP.announcement)), y = rep(yt, 2), adj = c(1, 0.5), labels = "announcement ", cex = cext)
      text(x = c(as.Date(date.SP.implementation), as.Date(date.VP.implementation)), y = rep(yt, 2), adj = c(0, 0.5), labels = " implementation", cex = cext)
      yt2 <- yt + 0.0
      cext2 <- 0.9
      text(x = mean(as.Date(c(date.SP.announcement, date.SP.implementation))), y = yt2, labels = "Sanitary\nPass", cex = cext2, adj = c(0.5, 0.5))
      text(x = mean(as.Date(c(date.VP.announcement, date.VP.implementation))), y = yt2, labels = "Vaccine\nPass", cex = cext2, adj = c(0.5, 0.5))
    }

    # Add legend
    legend("right", col = palCat, legend = paste(c("0-10%", 
                                                         "10-20%", 
                                                         "20-30%", 
                                                         "30-40%", 
                                                         "40-50%", 
                                                         "50-60%", 
                                                         "60-70%", 
                                                         "70-80%", 
                                                         "80-90%", 
                                                         "90-100%"), "quantile"), 
           cex = 0.8, pt.cex = 1, lwd = 2, box.lwd = 0, bg = gray(1, 0.75), inset = c(0.015, 0))
    
  }
  
}


