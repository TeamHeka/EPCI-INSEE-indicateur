# Function to do a logistic regression on one of the variables
getLogReg <- function(varVacc = "1_inj", varPred, thedate, predTransform, vaccAge, by.prbs = 0.1, permutation = FALSE, refAge = "40-54"){
  # 
  # varVacc  takes values "1_inj" or "termine"
  # varPred  is the predictor value to be used
  # thedate  date at which the calculations are done
  # predTransform: how to deal with the predictor values 
  #                "standardize_msd", "standardize_max" or "discretize" or "discretize_factor"
  # vaccAge: "raw_rates" if raw vaccination rates, without taking age into account
  #          "by_age" if model takes age into account
  #          "adjusted_rates" if adjusted vaccination rates and model on global rates
  #          "adults" all ages except 00-19
  # by.prbs  if "discretize", distance between breaks of the discretization
  # permutation Whether to permuate the predictors (for null hypothesis)
  # refAge   if "by_age", which age is taken as reference
  
  # Check data entry
  stopifnot(is.element(predTransform, c("standardize_msd", "standardize_max", "discretize", "discretize_factor")))
  stopifnot(is.element(varVacc, c("1_inj", "termine")))
  stopifnot(is.element(vaccAge, c("raw_rates", "by_age", "adjusted_rates", "adults")))
  
  stopifnot(is.element(varPred, names(dat.all)))
  
  # 1) How we treat the vaccination data
  if(vaccAge == "raw_rates"){
    # Subset vaccination data; keep only ALL_AGE
    r1 <- vacc[vacc$classe_age == "TOUT_AGE" & vacc$date == thedate, ]
    # Rename columns
    r1$taux_cumu <- r1[, paste0("taux_cumu_", varVacc)]
    r1$n_cumu <- r1[, paste0("effectif_cumu_", varVacc)]
  }
  if(vaccAge == "by_age"){
    # Subset vaccination data; keep all age classes except ALL_AGE
    r1 <- vacc[vacc$classe_age != "TOUT_AGE" & vacc$date == thedate, ]
    # Rename columns
    r1$taux_cumu <- r1[, paste0("taux_cumu_", varVacc)]
    r1$n_cumu <- r1[, paste0("effectif_cumu_", varVacc)]
  }
  if(vaccAge == "adjusted_rates"){
    # Subset vaccination data; keep all age classes except ALL_AGE
    tmp <- vacc[vacc$classe_age != "TOUT_AGE" & vacc$date == thedate, ]
    r1 <- adjustVacc(tmp, varVacc)
  }
  if(vaccAge == "adults"){
    # Subset vaccination data; keep all age classes except ALL_AGE
    tmp <- vacc[vacc$classe_age != "TOUT_AGE" & vacc$date == thedate, ]
    r1 <- adultVacc(tmp, varVacc)
  }

  # Merge with predictor data
  m1 <- merge(r1, dat.all[, c("codgeo", varPred)], by = "codgeo")
  
  # 2) How we treat the predictor
  pp <- m1[, varPred]
  if(predTransform == "standardize_msd"){
    m1$pred.std <- (pp - mean(pp, na.rm = TRUE)) / sd(pp, na.rm = TRUE)
  }
  if(predTransform == "standardize_max"){
    pMax <- max(pp, na.rm = TRUE)
    pMin <- min(pp, na.rm = TRUE)
    m1$pred.std <- (pp - pMin) / (pMax - pMin)
  }
  if(predTransform == "discretize"){
    m1$pred.std <- discretizeQ(v = pp, prbs = seq(0, 1, by = by.prbs))
  }
  if(predTransform == "discretize_factor"){
    m1$pred.std <- as.factor(discretizeQ(v = pp, prbs = seq(0, 1, by = by.prbs)))
  }
  
  # Permutation if we want to (to test significance)
  if(permutation){
    permi <- sample(seq_len(nrow(m1)))
    m1$pred.std <- m1[permi, "pred.std"]
  }
  
  # 3) The model: 
  # Logistic model
  if(vaccAge == "by_age"){
    # Logistic model, with age effect (age is factor)
    m1$age.f <- relevel(as.factor(m1$classe_age), refAge)
    mdl <- glm(cbind(n_cumu, population_carto - n_cumu) ~ pred.std + age.f + pred.std * age.f, family = binomial(link = "logit"), data = m1)
  }
  if(is.element(vaccAge, c("raw_rates", "adjusted_rates", "adults"))){
    # Logistic model, no age effect (but potentially adjusted)
    mdl <- glm(cbind(n_cumu, population_carto - n_cumu) ~ pred.std, family = binomial(link = "logit"), data = m1)
  }
  
  # Return model
  mdl
}