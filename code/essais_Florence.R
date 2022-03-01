#### INITIALIZATIONS ####

rm(list = ls())

# Package for odds ratios
library("epitools")
# Package for colors
library("RColorBrewer")
# Package for dynamical plots
library("plotly")

#library("igraph")

#### INSEE AND GEOGRAPHIC DATA ####

# The data have been dealt with in "0_INSEE_predictors.R" and saved as RData
load("../data/predictors.RData")

# Load region information for the different EPCI
regions <- read.csv("../data/geographic/EPCI_composition-communale.csv")
head(regions)
# Create dictionary 
dic.reg <- regions$REG
names(dic.reg) <- regions$EPCI

#### VACCINATION DATA ####

# Load data
#
# The files can be downloaded again (for updates) by running "0_loadAmeliData.R"
#

##
## EPCI 
##
vaccEPCI <- read.csv("../data/ameli_vaccination/vaccEPCI.csv", sep = ";")
head(vaccEPCI)

# Add region information
vaccEPCI$region <- dic.reg[as.character(vaccEPCI$epci)]
table(vaccEPCI$region, useNA = "ifany")  

# Note: NAs correspond to unattributed locations
unique(vaccEPCI[is.na(vaccEPCI$region), "epci"])

# Exclude DROM using regional code
vaccEPCI <- vaccEPCI[vaccEPCI$region > 9, ]

# Exclude Metropoles for which we have Communes detail
epci.PLM <- c(200054781, # Paris
              200046977, # Lyon
              200054807  # Marseille
              )
vaccEPCI <- vaccEPCI[which(!is.element(vaccEPCI$epci, epci.PLM)), ]

# Rename some fields for future merging
names(vaccEPCI)[c(3, 4)] <- c("codgeo", "libelle_geo")

##
## Communes
##
vaccCom <- read.csv("../data/ameli_vaccination/vaccCom.csv", sep = ";")
head(vaccCom)
# Rename some fields for future merging
names(vaccCom)[c(3, 4)] <- c("codgeo", "libelle_geo")

# Merge vaccination data into a single dataset
vacc <- rbind(vaccEPCI[, 1:16], vaccCom)

# Clean memory
rm(vaccCom, vaccEPCI)

# Make sure that population sizes are numeric
vacc$population_carto <- as.numeric(vacc$population_carto)

#### FUNCTIONS ####

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

# Test the fonction
#vv <- quantileConvert(dat.ACT[, 2], 0.25)
#mean(vv)

# Get all dates in the vaccination dataset
vaccDates <- sort(unique(vacc$date))

# Define specific dates
date1 <- "2021-07-11" # Just before pass sanitaire announcement
date2 <- "2021-08-08" # Just before pass sanitaire comes into force
date3 <- "2021-08-27" # Before back to school
date4 <- "2021-12-31" # Last date of the year


# Function to compute odds ratio and p value
computeOR <- function(pred, result, method = "fisher"){
  # pred   vector of the predictor, dichotomized
  # result vector of the result, dichotomized
  # method one of c("midp", "fisher", "wald", "small"), see ?oddsratio
  
  # Compute contingency table
  contTable <- table(pred, result)

  # Compute OR and pval
  or <- oddsratio(x = contTable, method = method)
  # Format the output
  out <- c(N = or$data[3, 3], or$measure[2, ], or$p.value[2, ])
  
  #print(or) # For debugging and double-checking
  out
}

# For debugging
# clAge <- "TOUT_AGE"
# varVacc <- "taux_cumu_1_inj"
# varPred <- "Overcrowding_rate"
# thedate <- date1
# dataTransform <- "discretize"

parms <- expand.grid(clAge = sort(unique(vacc$classe_age)), 
                     varVacc = c("taux_cumu_1_inj", "taux_cumu_termine"), 
                     varPred = names(dat.all[, -1]), 
                     thedate = c(date1, date2, date3, date4), stringsAsFactors = FALSE)

getOR <- function(clAge, varVacc, varPred, thedate, thrVacc = 0.25, thrPred = 0.5){
  # clAge age class
  # varVacc variable for the vaccination data
  # varPred variable for the predictor
  # thedate date of the vaccination data
  # thrVacc threshold value for dichotomizing vaccination data
  # thrPred threshold value for dichotomizing predictor data
  
  # Subset vaccination data
  r1 <- vacc[vacc$classe_age == clAge & vacc$date == thedate, ]

  # Merge with predictor data
  m1 <- merge(r1, dat.all[, c("codgeo", varPred)], by = "codgeo")

  # Dichotomize the vectors
  result <- quantileConvert(m1[, varVacc], thrVacc)
  pred <- quantileConvert(m1[, varPred], thrPred)

  # Compute OR
  computeOR(pred, result)
#  output <- c(date = thedate, varVacc = varVacc, clAge = clAge, varPred = varPred, computeOR(pred, result))
#  output
}

# Compute for all combinations that we want
# (Takes a few minutes)
nrow(parms)
output <- matrix(0, ncol = 7, nrow = nrow(parms))
for(i in 1:nrow(parms)){
  cat(i, "")
  output[i, ] <- do.call(getOR, parms[i, ])
}

# For debugging
getOR("TOUT_AGE", "taux_cumu_1_inj", "Overcrowding_rate", date1, thrVacc = 0.25, thrPred = 0.5)
  
  
# Add the parameter information
mm <- cbind(parms, output)

names(mm) <- c("clAge", "varVacc", "varPred", "thedate", "N", "estimate", "lower", "upper", "midp.exact", "fisher.exact", "chi.square")

# Save the output
save(mm, file = "output_OR.RData")

###### ANOVA ##########
anovaVacc <- function(clAge, varVacc, varPred, thedate, thrPred = c(0.1, 0.9)){
  # clAge age class
  # varVacc variable for the vaccination data
  # varPred variable for the predictor
  # thedate date of the vaccination data
  # thrPred threshold value(s) for dichotomizing predictor data
  #         if one value, all data are binarized as 0: v<q, 1: v>=q
  #         if two values, 0: v<q1, NA: q1<= v <=q2, 1: v>q2
          
  
  # Subset vaccination data
  r1 <- vacc[vacc$classe_age == clAge & vacc$date == thedate, ]
  
  # Merge with predictor data
  m1 <- merge(r1, dat.all[, c("codgeo", varPred)], by = "codgeo")
  
  # Dichotomize the vector
  if(length(thrPred) == 1){
    m1$pred <- quantileConvert(m1[, varPred], thrPred)
  }else{
    m1$pred <- quantilesConvert(m1[, varPred], thrPred[1], thrPred[2])
  }
  m1$res <- m1[, varVacc]
  
  aov(res ~ pred, data = m1)
}


mdl <- anovaVacc("TOUT_AGE", "taux_cumu_1_inj", "Overcrowding_rate", date3)
(mdl$coefficients)[["pred"]]
summary(mdl)

effect3 <- rep(0, ncol(dat.all)-1)
for(i in 2:ncol(dat.all)){
  mdl <- anovaVacc("TOUT_AGE", "taux_cumu_1_inj", names(dat.all)[i], date3)
  effect3[i-1] <- (mdl$coefficients)[["pred"]]
}

summary(mdl)

#### LOGISTIC REGRESSION ####----

# Function to discretize wrt to quantiles
discretizeQ <- function(v, prbs = seq(0, 1, by = 0.05)){
  # v     vector to discretize
  # prbs  positions of the boundaries
  
  # Define deciles, and set extreme values to 0 and 1
  qq <- c(quantile(v, probs = prbs, na.rm = TRUE))
  qq[1] <- 0
  qq[length(qq)] <- 1
  
  # Add noise to avoid issues when data are too close
  noise <- c(0, runif(length(prbs)-2, max = 10^(-6)), 0)
  qq <- sort(qq + noise)
  
  # Put the values of v in the different classes
  out <- cut(v, breaks = qq, right = FALSE, labels = FALSE)
  out
}

# Function to do a logistic regression on one of the variables
getLogReg <- function(varVacc, varPred, thedate, dataTransform, byAge){
  # varPred takes values "taux_cumu_1_inj" or "taux_cumu_termine"
  #
  #
  # dataTransform: "standardize" or "discretize"
  # byAge:         boolean, whether to use age classes or not
  
  # Check data entry
  stopifnot(is.element(dataTransform, c("standardize", "discretize")) & is.element(varVacc, c("taux_cumu_1_inj", "taux_cumu_termine")))
  
  if(byAge){
    # Subset vaccination data; keep all age classes except ALL_AGE
    r1 <- vacc[vacc$classe_age != "TOUT_AGE" & vacc$date == thedate, ]
  }else{
    # Subset vaccination data; keep only ALL_AGE
    r1 <- vacc[vacc$classe_age == "TOUT_AGE" & vacc$date == thedate, ]
  }
  
  # Merge with predictor data
  m1 <- merge(r1, dat.all[, c("codgeo", varPred)], by = "codgeo")
  
  # Standardize the predictor
  pp <- m1[, varPred]
  
  if(dataTransform == "standardize"){
    m1$pred.std <- (pp - mean(pp, na.rm = TRUE)) / sd(pp, na.rm = TRUE)
  }
  if(dataTransform == "discretize"){
    m1$pred.std <- discretizeQ(pp)
  }
  
  if(byAge){
    # Logistic model, with age effect
    if(varVacc == "taux_cumu_1_inj"){
      mdl <- glm(cbind(effectif_cumu_1_inj, population_carto - effectif_cumu_1_inj) ~ pred.std + as.factor(classe_age) + pred.std * as.factor(classe_age), family = binomial(link = "logit"), data = m1)
    }
    if(varVacc == "taux_cumu_termine"){
      mdl <- glm(cbind(effectif_cumu_termine, population_carto - effectif_cumu_termine) ~ pred.std + as.factor(classe_age) + pred.std * as.factor(classe_age), family = binomial(link = "logit"), data = m1)
    }
  }else{
    # Logistic model, no age effect
    if(varVacc == "taux_cumu_1_inj"){
      mdl <- glm(cbind(effectif_cumu_1_inj, population_carto - effectif_cumu_1_inj) ~ pred.std, family = binomial(link = "logit"), data = m1)
    }
    if(varVacc == "taux_cumu_termine"){
      mdl <- glm(cbind(effectif_cumu_termine, population_carto - effectif_cumu_termine) ~ pred.std, family = binomial(link = "logit"), data = m1)
    }
  }

  # Extract values for pred.std
  out <- summary(mdl)$coefficients["pred.std", ]
  mdl
}

tmp <- getLogReg("taux_cumu_1_inj", "Overcrowding_rate", thedate = date1, dataTransform = "discretize", byAge = TRUE)
summary(tmp)
tmp <- getLogReg("taux_cumu_1_inj", "Overcrowding_rate", thedate = date1, dataTransform = "standardize", byAge = FALSE)
summary(tmp)

parmsLR <- expand.grid(varVacc = c("taux_cumu_1_inj", "taux_cumu_termine"), 
                     varPred = names(dat.all[, -1]), 
                     thedate = c(date1, date2, date3), 
                     dataTransform = c("standardize", "discretize"),
                     byAge = c(TRUE, FALSE),
                     stringsAsFactors = FALSE)
# Compute for all combinations that we want
# (Takes a few minutes)
outputLR <- matrix(0, ncol = 4, nrow = nrow(parmsLR))
for(i in 1:nrow(parmsLR)){
  cat(i, " ")
  outputLR[i, ] <- do.call(getLogReg, parmsLR[i, ])
}


oLR <- cbind(parmsLR, outputLR)
oLR


save(oLR, file = "output_LR.RData")

#########----------------

#### PLOT ####

load("output_OR.RData")
# OR as 1/OR if < 1
mm$OR <- mm$estimate

mm[mm$OR < 1, "OR"] <- 1/mm[mm$OR < 1, "OR"]
mm$ORlower <- mm$lower
mm[mm$estimate < 1, "ORlower"] <- 1 / mm[mm$estimate < 1, "upper"]
  
mm$ORupper <- mm$upper
mm[mm$estimate < 1, "ORupper"] <- 1 / mm[mm$estimate < 1, "lower"]

tmp <- mm[mm$thedate == date1 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == "TOUT_AGE", ]

#plot(tmp$estimate)

#plot(-log(tmp$midp.exact, 10))

plot(tmp$OR, -log(tmp$fisher.exact, 10), col = colClass[dicPred[tmp$varPred]], pch = 16)
legend("topleft", legend = names(colClass), col = colClass, pch = 16)

tmp[order(tmp$OR, decreasing = TRUE), c("varPred", "OR")]


clA <- "TOUT_AGE"
tmp1 <- mm[mm$thedate == date1 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == clA, ]
tmp3 <- mm[mm$thedate == date3 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == clA, ]

head(tmp1)
plot(tmp1$OR, tmp3$OR, pch = 16, col = colClass[dicPred[tmp$varPred]], 
     frame.plot = FALSE, 
     xlim = c(0, max(c(tmp1$ORupper, tmp3$ORupper))), 
     ylim = c(0, max(c(tmp1$ORupper, tmp3$ORupper))), 
     xaxs = "i", yaxs = "i")
abline(a = 0, b = 1)
legend("topleft", legend = names(colClass), col = colClass, pch = 16)

arrows(x0 = tmp1$ORlower, x1 = tmp1$ORupper, 
       y0 = tmp3$OR, y1 = tmp3$OR, 
       col = colClass[dicPred[tmp$varPred]], 
       code = 0)
arrows(x0 = tmp1$OR, x1 = tmp1$OR, 
       y0 = tmp3$ORlower, y1 = tmp3$ORupper, 
       col = colClass[dicPred[tmp$varPred]], 
       code = 0)

#all(tmp1$varPred == names(dat.all)[2:ncol(dat.all)])
tmpOR <- data.frame(t1 = tmp1$OR, t3 = tmp3$OR, vp = tmp1$varPred, type = dicPred[tmp1$varPred], col = colClass[dicPred[tmp1$varPred]], sz = ifelse(tmp1$fisher.exact < 0.05/300 & tmp3$fisher.exact < 0.05/300, 3, 1), p1 = tmp1$fisher.exact, p3 = tmp3$fisher.exact, effect3 = round(100*abs(effect3)))


figOR <- plot_ly(tmpOR, x = ~t1, y = ~t3, 
               text = ~paste(type, "", vp, "\n p1=", p1, "p3 = ", p3, "\n effect=", effect3), color = ~col, 
               type = "scatter", 
               size = ~effect3)
figOR

tmp1






(tmp3[order(tmp3$OR, decreasing = TRUE), c("varPred", "OR", 'estimate'), ])[1:10, ]


tmpp1 <- vacc[vacc$date == date1 & vacc$classe_age == "TOUT_AGE", ]
tmppp1 <- merge(tmpp1, dat.all, by = "codgeo")
tmpp3 <- vacc[vacc$date == date3 & vacc$classe_age == "TOUT_AGE", ]
tmppp3 <- merge(tmpp3, dat.all, by = "codgeo")
plot(tmppp3$Overcrowding_rate, tmppp3$taux_cumu_1_inj, ylim = c(0, 1))
points(tmppp1$Overcrowding_rate, tmppp1$taux_cumu_1_inj, col = 2)


#########################
library(plotly)
?plotly

dT <- "discretize"
ba <- TRUE

names(oLR) <- c(names(parmsLR), c("Estimate", "StdError", "z_value", "p"))
tmp1 <- oLR[oLR$thedate == date1 & oLR$varVacc == "taux_cumu_1_inj" & oLR$dataTransform == dT & oLR$byAge == ba, ]
tmp3 <- oLR[oLR$thedate == date3 & oLR$varVacc == "taux_cumu_1_inj" & oLR$dataTransform == dT & oLR$byAge == ba, ]

par(xpd = FALSE)
plot(tmp1$Estimate, tmp3$Estimate, col = colClass[dicPred[tmp1$varPred]], pch = 16, cex = 0.8)
arrows(x0 = tmp1$Estimate - 1.96 * tmp1$StdError, 
       y0 = tmp3$Estimate, 
       x1 = tmp1$Estimate + 1.96 * tmp1$StdError, 
       y1 = tmp3$Estimate, 
       col = colClass[dicPred[tmp1$varPred]], code = 0)

arrows(x0 = tmp1$Estimate, 
       y0 = tmp3$Estimate - 1.96 * tmp3$StdError, 
       x1 = tmp1$Estimate, 
       y1 = tmp3$Estimate + 1.96 * tmp3$StdError, 
       col = colClass[dicPred[tmp1$varPred]], code = 0)

abline(a = 0, b = 1)
abline(h = 0)
abline(v = 0)
legend("topleft", legend = names(colClass), col = colClass, pch = 16)



tmp <- data.frame(t1 = tmp1$Estimate, t3 = tmp3$Estimate, vp = tmp1$varPred, type = dicPred[tmp1$varPred], col = colClass[dicPred[tmp1$varPred]], sz = ifelse(tmp1$p < 0.05/300 & tmp3$p < 0.05/300, 3, 1), p1 = tmp1$p, p3 = tmp3$p)

tmp


fig <- plot_ly(tmp, x = ~t1, y = ~t3, 
               text = ~paste(type, "", vp, "\n p1=", p1, "p3 = ", p3), color = ~col, 
               type = "scatter", 
               size = ~sz)
fig


ageCol <- brewer.pal(length(unique(vacc$classe_age)), "Set1")
names(ageCol) <- sort(unique(vacc$classe_age))


varPred <- "Poverty"
thedate <- date1

plotPred <- function(varPred, thedate, dataTransform, qt = seq(0, 1, by = 0.05)){
  v1 <- vacc[vacc$date == thedate & vacc$classe_age != "TOUT_AGE", ]
  p1 <- dat.all[, c("codgeo", varPred)]
  m1 <- merge(v1, p1, by = "codgeo")
  pp <- m1[, varPred]
  if(dataTransform == "none"){
    m1$pred <- pp
  }
  if(dataTransform == "standardize"){
    m1$pred <- (pp - mean(pp, na.rm = TRUE)) / sd(pp, na.rm = TRUE)
  }
  if(dataTransform == "discretize"){
    m1$pred <- discretizeQ(pp, prbs = qt)
  }
  
  plot(m1$pred, m1$taux_cumu_1_inj, col = ageCol[m1$classe_age], pch = 16, cex = 0.6, 
       ylim = c(0, 1), 
       xlab = varPred, 
       ylab = "Taux cumu 1 inj", xaxs = "i", yaxs = "i")
  for(i in seq(0, 1, by = 0.1)){
    abline(h = i, col = gray(0, 0.2))
  }
  
  mdl <- glm(cbind(effectif_cumu_1_inj, population_carto - effectif_cumu_1_inj) ~ pred + as.factor(classe_age) + pred * as.factor(classe_age), family = binomial(link = "logit"), data = m1)
  
  newdata <- expand.grid(pred = seq(min(m1$pred, na.rm = TRUE), max(m1$pred, na.rm = TRUE), length.out = 100), classe_age = names(ageCol)[1:6])
  
  ndt <- newdata
  ndt$prd1D <- predict(mdl, newdata = newdata, type = "response")
  
  lwd.pred <- 2
  for(age in unique(ndt$classe_age)){
    # Get predicted data for this age class (no region)
    subd <- ndt[ndt$classe_age == age,]
    lines(subd$pred, subd$prd1D, col = ageCol[age], lwd = lwd.pred)
  }
}

plotPred("Overcrowding_rate", date3, "standardize")

tmp1[tmp1$varPred == "Overcrowding_rate", ]
tmp3[tmp3$varPred == "Overcrowding_rate", ]

plotPred("D1_st_Living", date1, "standardize")
plotPred("D1_st_Living", date3, "standardize")

plotPred("D1_st_Living", date1, "discretize")

plotPred("SENO", date1, "discretize")
plotPred("SENO", date3, "discretize")

plotPred("Farmer_HH", date3, "discretize")

#########################











#######################
0.05/300
-log(0.05/300, 10)

hist(-log(tmp$fisher.exact, 10))

do.call(getOR, parms[i,])

getOR(parms[i, "clAge"], parms[i, "varVacc"], parms[i, "varPred"], parms[i, "thedate"])



########## Discreticize

a <- runif(100)
qq <- c(quantile(a, probs = seq(0, 1, by = 0.1)))
qq[1] <- 0
qq[length(qq)] <- 1
b <- cut(a, breaks = qq, right = FALSE, labels = FALSE)
b
plot(a, b)

r1 <- vacc[which(vacc$classe_age == "TOUT_AGE" & vacc$date == date1), ]
r1[1:2,]
sum(r1$population_carto)
