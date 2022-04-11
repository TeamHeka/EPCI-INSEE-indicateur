# Extract OR from logistic model where the predictor is a factor
extractOR <- function(mdl, nstd = NA){

  # If not `nstd` is specified, take the last one
  if(is.na(nstd)){
    nstd <- length(mdl$coefficients)
  }
  
  pred <- paste0("pred.std", nstd)
  # mdl is the mdl obtained with a logistic regression, with a discretized and factorized predictor
  # pred is the predictor value on which ORs are computed
  
  OR <- exp(summary(mdl)$coefficients[pred, "Estimate"])
  OR.CI.min <- exp(summary(mdl)$coefficients[pred, 1] + 1.96 * summary(mdl)$coefficients[pred, 2])
  OR.CI.max <- exp(summary(mdl)$coefficients[pred, 1] - 1.96 * summary(mdl)$coefficients[pred, 2])
  
  # Compute max(OR, 1/OR)
  # (not taking it directly because CI may straddle the value 1)
  inv <- (OR < 1)
  if(inv){
    OR.abs <- 1/OR
    OR.abs.CI.min <- 1/OR.CI.min
    OR.abs.CI.max <- 1/OR.CI.max
  }else{
    OR.abs <- OR
    OR.abs.CI.min <- OR.CI.min
    OR.abs.CI.max <- OR.CI.max
  }
  
  # Predicted values of the extreme categories
  predMin <- invlogit(summary(mdl)$coefficients["(Intercept)", "Estimate"])
  predMax <- invlogit(summary(mdl)$coefficients["(Intercept)", "Estimate"] + summary(mdl)$coefficients[pred, "Estimate"])
  
  # Return output
  c(OR = OR, 
    OR.CI.min = OR.CI.min, 
    OR.CI.max = OR.CI.max, 
    OR.abs = OR.abs, 
    OR.abs.CI.min = OR.abs.CI.min,
    OR.abs.CI.max = OR.abs.CI.max, 
    predMin = predMin, 
    predMax = predMax)
}

#....................................................................................

# Compute adjusted predicted values
adjustedPredict <- function(mdl, newd, includeChildren = TRUE, distributionAges = distAge){
  # mdl is model by age
  # newd is new data for the predicted values
  # includeChildren is a boolean indicating whether the 00-19 age class should be included in the adjusted rate
  # distAge is the age distribution in France
  
  # Compute predicted values
  preds <- cbind(newd, pred = predict(mdl, newdata = newd, type = "response"))

  # Recompute distAge in case we exclude children
  dA <- distributionAges
  if(!includeChildren){
    # Remove 00-19
    dA <- dA[dA$classe_age != "00-19", ]
    # Recompute proportions
    dA$p <- dA$x / sum(dA$x)
  }

  # Add the proportion information
  preds <- merge(preds, dA, by = "age.f")

  out <- aggregate(preds$pred * preds$p, by = list(pred.std = preds$pred.std), FUN = sum)
  names(out)[which(names(out) == "x")] <- "adjustedRate"
  out
}

#....................................................................................

# Construct OR from predicted values
getORfromPredict <- function(rates){
  # rates: rates of the two outcomes to compare
  OR <- rates[1] * (1 - rates[2]) / (rates[2] * (1 - rates[1]))
  OR
}


