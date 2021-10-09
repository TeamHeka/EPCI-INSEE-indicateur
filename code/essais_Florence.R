#### INITIALIZATIONS ####

rm(list = ls())
library("epitools")

library("RColorBrewer")

library("igraph")



#### VACCINATION DATA ####

# Load data

##
## EPCI 
##
vaccEPCI <- read.csv("../data/ameli_vaccination/vaccEPCI.csv", sep = ";")
head(vaccEPCI)

# Add region information
vaccEPCI$region <- dic.reg[as.character(vaccEPCI$epci)]
unique(vaccEPCI$region)  

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

# Test
#vv <- quantileConvert(dat.ACT[, 2], 0.25)
#mean(vv)

# Get all dates in the vaccination dataset
vaccDates <- sort(unique(vacc$date))

# Define specific dates
date1 <- "2021-07-11" # Just before pass sanitaire announcement
date2 <- "2021-08-08" # Just before pass sanitaire comes into force
date3 <- max(vaccDates) # Final date in the dataset


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
  
  print(or) # For debugging and double-checking
  out
}

# For debugging
clAge <- "TOUT_AGE"
varVacc <- "taux_cumu_1_inj"
varPred <- "Overcrowding_rate"
thedate <- date1

parms <- expand.grid(clAge = sort(unique(vacc$classe_age)), 
                     varVacc = c("taux_cumu_1_inj", "taux_cumu_termine"), 
                     varPred = predNames, 
                     thedate = c(date1, date2, date3), stringsAsFactors = FALSE)

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
output <- matrix(0, ncol = 7, nrow = nrow(parms))
for(i in 1:nrow(parms)){
  output[i, ] <- do.call(getOR, parms[i, ])
}


getOR("TOUT_AGE", "taux_cumu_1_inj", "Overcrowding_rate", date1, thrVacc = 0.25, thrPred = 0.5)
  
  
# Add the parameter information
mm <- cbind(parms, output)

names(mm) <- c("clAge", "varVacc", "varPred", "thedate", "N", "estimate", "lower", "upper", "midp.exact", "fisher.exact", "chi.square")

# Save the output
save(mm, file = "output_2021-10-07.RData")

########----

rm(r1, m1, pp)
rm(mdl)

getLogReg <- function(varVacc, varPred, thedate){
  # varPred takes values "taux_cumu_1_inj" or "taux_cumu_termine"
  
  # Subset vaccination data; keep all age classes except ALL_AGE
  r1 <- vacc[vacc$classe_age != "TOUT_AGE" & vacc$date == thedate, ]
  
  # Merge with predictor data
  m1 <- merge(r1, dat.all[, c("codgeo", varPred)], by = "codgeo")
  
  # Standardize the predictor
  pp <- m1[, varPred]
  m1$pred.std <- (pp - mean(pp, na.rm = TRUE)) / sd(pp, na.rm = TRUE)
  
  # Logistic model, with age effect
  if(varVacc == "taux_cumu_1_inj"){
    mdl <- glm(cbind(effectif_cumu_1_inj, population_carto - effectif_cumu_1_inj) ~ pred.std + as.factor(classe_age) + pred.std * as.factor(classe_age), family = binomial(link = "logit"), data = m1)
  }
  if(varVacc == "taux_cumu_termine"){
    mdl <- glm(cbind(effectif_cumu_termine, population_carto - effectif_cumu_termine) ~ pred.std + as.factor(classe_age) + pred.std * as.factor(classe_age), family = binomial(link = "logit"), data = m1)
  }

  # Extract values for pred.std
  out <- summary(mdl)$coefficients["pred.std", ]
  out
}

getLogReg("taux_cumu_1_inj", "Overcrowding_rate", date1)


parmsLR <- expand.grid(varVacc = c("taux_cumu_1_inj", "taux_cumu_termine"), 
                     varPred = predNames, 
                     thedate = c(date1, date2, date3), stringsAsFactors = FALSE)
# Compute for all combinations that we want
# (Takes a few minutes)
outputLR <- matrix(0, ncol = 4, nrow = nrow(parmsLR))
for(i in 1:nrow(parmsLR)){
  outputLR[i, ] <- do.call(getLogReg, parmsLR[i, ])
}

oLR <- cbind(parmsLR, outputLR)
oLR


save(oLR, file = "output_LR.RData")

#########----------------

#### PLOT ####

load("output_2021-10-07.RData")
# OR as 1/OR if < 1
mm$OR <- mm$estimate
mm[mm$OR < 1, "OR"] <- 1/mm[mm$OR < 1, "OR"]

tmp <- mm[mm$thedate == date1 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == "TOUT_AGE", ]

#plot(tmp$estimate)

#plot(-log(tmp$midp.exact, 10))

plot(tmp$OR, -log(tmp$fisher.exact, 10), col = colClass[dicPred[tmp$varPred]], pch = 16)
legend("topleft", legend = names(colClass), col = colClass, pch = 16)

tmp[order(tmp$OR, decreasing = TRUE), c("varPred", "OR")]


clA <- "20-39"
tmp1 <- mm[mm$thedate == date1 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == clA, ]
tmp3 <- mm[mm$thedate == date3 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == clA, ]

head(tmp1)
plot(tmp1$OR, tmp3$OR, pch = 16, col = colClass[dicPred[tmp$varPred]], 
     xlim = range(c(tmp1$OR, tmp3$OR)), 
     ylim = range(c(tmp1$OR, tmp3$OR)))
abline(a = 0, b = 1)
legend("topleft", legend = names(colClass), col = colClass, pch = 16)

(tmp3[order(tmp3$OR, decreasing = TRUE), c("varPred", "OR", 'estimate'), ])[1:10, ]


tmpp1 <- vacc[vacc$date == date1 & vacc$classe_age == "TOUT_AGE", ]
tmppp1 <- merge(tmpp1, dat.all, by = "codgeo")
tmpp3 <- vacc[vacc$date == date3 & vacc$classe_age == "TOUT_AGE", ]
tmppp3 <- merge(tmpp3, dat.all, by = "codgeo")
plot(tmppp3$Overcrowding_rate, tmppp3$taux_cumu_1_inj, ylim = c(0, 1))
points(tmppp1$Overcrowding_rate, tmppp1$taux_cumu_1_inj, col = 2)


#########################
names(oLR) <- c(names(parmsLR), c("Estimate", "Std. Error", "z_value", "p"))
tmp1 <- oLR[oLR$thedate == date1 & oLR$varVacc == "taux_cumu_1_inj", ]
tmp3 <- oLR[oLR$thedate == date3 & oLR$varVacc == "taux_cumu_1_inj", ]
tmp

-log(0.05/300)



plot(-log(tmp$p, 10))


plot(abs(tmp1$Estimate), col = colClass[dicPred[tmp1$varPred]], pch = 16)

tmp1[order(abs(tmp1$Estimate), decreasing = TRUE), ][1:10, ]

par(xpd = FALSE)
plot(abs(tmp1$Estimate), tmp3$Estimate, col = colClass[dicPred[tmp1$varPred]], pch = 16)
abline(a = 0, b = 1)
abline(h = 0)
abline(v = 0)

library(plotly)
?plotly


tmp <- data.frame(t1 = tmp1$Estimate, t3 = tmp3$Estimate, vp = tmp1$varPred, type = dicPred[tmp1$varPred], col = colClass[dicPred[tmp1$varPred]], sz = ifelse(tmp1$p < 0.05/300 & tmp3$p < 0.05/300, 3, 1), p1 = tmp1$p, p3 = tmp3$p)

tmp

fig <- plot_ly(tmp, x = ~t1, y = ~t3, 
               text = ~paste(type, "", vp, "\n p1=", p1, "p3 = ", p3), color = ~col, 
               type = "scatter", 
               size = ~sz)
fig


,
  # Hover text:
  text = ~paste("Price: ", price, '$<br>Cut:', cut),
  color = ~colClass[dicPred[tmp1$varPred]]
)

fig



#########################











#######################
0.05/300
-log(0.05/300, 10)

hist(-log(tmp$fisher.exact, 10))

do.call(getOR, parms[i,])

getOR(parms[i, "clAge"], parms[i, "varVacc"], parms[i, "varPred"], parms[i, "thedate"])


parms[8,]
parms[1:10,]



vacc$taux_cumu_termine

# Compute contigency table
computeORTable <- 

  
v1 <- dat.ACT[, 2]
v2 <- 
?quantile
quantile(dat.ACT[, 2], probs = 0.5)



# This is the data already presented as factors
LOG_fact <- read.csv("../data/Factors/LOG_fact.csv")
head(LOG_fact)


LOG <- read.csv("../data/export_INSEE/LOG.csv", sep = ";")
head(LOG)

read.csv("../data/Factors/")
EMP_fact <- read.csv("data/EMP_fact.csv")
ACT_fact <- read.csv("data/ACT_fact.csv")
REV_fact <- read.csv("data/REV_fact.csv")
POP_fact <- read.csv("data/POP_fact.csv")
FOR_fact <- read.csv("data/FOR_fact.csv")
IMM_fact <- read.csv("data/IMM_fact.csv")
GEO_fact <- read.csv("data/GEO_fact.csv")
FAM_fact <- read.csv("data/FAM_fact.csv")
