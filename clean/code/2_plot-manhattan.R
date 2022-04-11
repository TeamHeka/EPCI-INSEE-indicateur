# Define palette
library("MetBrewer")

pal <- met.brewer("Signac", 10, type= "discrete")
# Reorder for better contrast
pal <- pal[c(1, 6, 2, 7, 3, 8, 4, 9, 5, 10)]

pal <- c("#a6cee3", "#e31a1c", "#1f78b4", "#fdbf6f", "#b2df8a", "#ff7f00", "#33a02c", "#cab2d6", "#fb9a99", "#6a3d9a")
names(pal) <- unique(dicPred[names(dat.nocorr[-1])])
# plot(1:10, col = pal, cex = 2, pch = 15)

colPerm <- gray(0, 0.4)


#...............................................................................
# Manhattan plot
plotManhattan <- function(out, qq = 0.99, ntop = 3){
  # out is the output table, containing ORs and the parameters
  # qq quantile for the permuted values
  # ntop is number of labels to plot
  
  # Extract date values
  thedates <- sort(unique(out$thedate))
  
  # xMax value
  xMax <- 1.05 * max(out$OR.abs.CI.max)
  
  for(thedate in thedates){
    # Subsets of the data at this date
    subF <- out[out$thedate == thedate & out$permutation == FALSE, ]
    subT <- out[out$thedate == thedate & out$permutation == TRUE, ]
    
    subF$i <- seq_len(nrow(subF)) # Add index
    
    # Initialize plot
    par(mar = c(3, 5, 2, 2.3), mgp = c(1.25, 0.5, 0))
    plot(0, xlim = c(1, xMax), ylim = c(1, nrow(subF)), type = "n", 
         axes = FALSE, xlab = "max(OR, 1/OR)", ylab = "")
    axis(1, pos = 1, lwd = 0, lwd.ticks = 1, tck = -0.01)
    
    types <- unique(out$typePred)
    for(tp in types){
      # Subset of the data for this type
      subb <- subF[subF$typePred == tp, ]
      rg <- range(subb$i)
      op <- 0.2
      dx <- 0.5 # 0.5 for no space
      rect(xleft = 1, xright = xMax, 
           ybottom = rg[1] - dx, ytop = rg[2] + dx, 
           border = gray(0, 0), col = adjustcolor(pal[tp], op))
      par(xpd = TRUE)
      # Plot label
      text(x = 1, y = mean(rg), labels = paste0(dic.fullpred[tp], " "), col = pal[tp], adj = c(1, 0.5))
      
      # Plot points
      points(subb$OR.abs, subb$i, col = pal[tp], pch = 16)
    }
    
    # Plot permuted values
    # Get value of the qq quantile
    xq <- quantile(subT$OR.abs, probs = qq)
    # Plot rectangle delimiting the values
    rect(xleft = 1, xright = xq, 
         ybottom = 1 - dx, ytop = nrow(subF) + dx, 
         border = gray(0, 0), col = colPerm)
    # Add label for the quantile
    text(x = xq, y = 1, adj = c(0.5, 1.5), cex = 0.7, labels = paste0(as.character(100*qq), "%"))
    
    # Label the most important values
    tmp <- subF[order(subF$OR.abs, decreasing = TRUE), ][1:ntop, ]
    # Remove X if any
    iX <- which(substr(tmp$varPred, 1, 1) == "X")
    tmp[iX, "varPred"] <- vapply(tmp[iX, "varPred"], FUN = function(x) substr(x, 2, nchar(x)), FUN.VALUE = "x")
    
    arrs <- rep("(+)", ntop)
    arrs[tmp$OR < 1] <- "(-)"
    text(y = tmp$i, x = tmp$OR.abs, adj = c(0, 0.5), labels = paste0("   ", tmp$varPred, " ", arrs), cex = 0.7)
    
    # Add title
    title(main = thedate)
  } # end date loop
}


