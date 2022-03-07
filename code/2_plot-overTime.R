

plotPropTime <- function(out){
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
    
    # Subset of the data for this predictor
    sub <- out[out$varPred == varPred, ]
    
    # Plot the predicted values
    for(i in 1:nn){
      lines(as.Date(sub$thedate), sub[, paste0("V", i)], col = palCat[i], lwd = 2)
    }
    
    # Add legend
    legend("bottomright", col = palCat, legend = paste(c("0-10%", 
                                                         "10-20%", 
                                                         "20-30%", 
                                                         "30-40%", 
                                                         "40-50%", 
                                                         "50-60%", 
                                                         "60-70%", 
                                                         "70-80%", 
                                                         "80-90%", 
                                                         "90-100%"), "quantile"), 
           cex = 0.8, pt.cex = 1, lwd = 2, bty = "n")
  }
  
}
