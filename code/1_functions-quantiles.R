# Convert to binary values depending on a chosen threshold
quantileConvert <- function(v, q){
  # v vector to be converted
  # q chosen quantile (between 0 and 1)
  
  # Compute the threshold value
  # Rem: need to remove NAs
  qval <- quantile(x = v, probs = q, na.rm = TRUE)
  
  # Return TRUE/FALSE depending on the position wrt the value, and change into 1/0
  out <- ifelse(v < qval, 0, 1)
  out
}

#.......................................................................

# Convert to binary values, with respect to 2 threshold values
quantilesConvert <- function(v, qmin = 0.1, qmax = 0.9){
  # v vector to be converted
  # qmin lower threshold value, data below it are coded 0
  # qmax higher threshold value, data above it are coded 1
  # and data between qmin and qmax are coded NA
  
  # Compute the threshold value
  # Rem: need to remove NAs
  qval <- quantile(x = v, probs = c(qmin, qmax), na.rm = TRUE)
  
  out <- rep(NA, length(v)) # Initialize output vector
  out[v < qval[1]] <- 0 
  out[v > qval[2]] <- 1
  
  out
}

#.......................................................................

# Discretize wrt to quantiles 
discretizeQ <- function(v, prbs = seq(0, 1, by = 0.05)){
  # v     vector to discretize
  # prbs  positions of the boundaries
  
  # Define quantiles
  qq <- c(quantile(v, probs = prbs, na.rm = TRUE))
  
  # Extend the extreme values to make sure that they are included later
  qq[1] <- qq[1] - abs(0.5 * qq[1]) # 0%
  qq[length(qq)] <- qq[length(qq)] + abs(0.5 * qq[length(qq)]) # 100%
  
  # Add noise to avoid issues with the `cut` function when data are too close
  noise <- c(0, runif(length(prbs)-2, max = 10^(-6)), 0)
  qq <- sort(qq + noise)
  
  # Put the values of v in the different classes
  out <- cut(v, breaks = qq, right = FALSE, labels = FALSE)
  # table(out, useNA = "ifany")
  out
}

