#### INITIALIZATIONS ####

# rm(list = ls())
library("epitools")

library("RColorBrewer")

#### INSEE AND GEO DATA ####

# Activity data
dat.ACT <- read.csv("../data/INSEE_transformed/ACT_brut.csv", sep = ";", dec = ",")
head(dat.ACT)
# Remove last column 
dat.ACT <- dat.ACT[, 1:(ncol(dat.ACT)-1)]

# Employment data
dat.EMP <- read.csv("../data/INSEE_transformed/EMP_brut.csv", sep = ";", dec = ",")
head(dat.EMP)
# Remove last column 
dat.EMP <- dat.EMP[, 1:(ncol(dat.EMP)-1)]

# Family data
dat.FAM <- read.csv("../data/INSEE_transformed/FAM_brut.csv", sep = ";", dec = ",")
head(dat.FAM)
# Remove last column 
dat.FAM <- dat.FAM[, 1:(ncol(dat.FAM)-1)]

# Education data
dat.FOR <- read.csv("../data/INSEE_transformed/FOR_brut.csv", sep = ";", dec = ",")
head(dat.FOR)
# Remove last column 
dat.FOR <- dat.FOR[, 1:(ncol(dat.FOR)-1)]

# Geographic data -- MISSING
# dat.GEO <- read.csv("../data/INSEE_transformed/GEO_brut.csv", sep = ";", dec = ",")
#tail(dat.GEO)
# Remove last column 
# dat.GEO <- dat.GEO[, -5]

dat.GEO <- read.csv("../data/geographic/exportGeo_EPCI.csv")
dat.GEO <- dat.GEO[, -1]
head(dat.GEO)
names(dat.GEO) <- c("long", "lat", "surf", "codgeo")
# Compute diagonal values
dat.GEO$SONE <- dat.GEO$lat + dat.GEO$long
dat.GEO$SENO <- dat.GEO$lat - dat.GEO$long

# Immigration data 
dat.IMM <- read.csv("../data/INSEE_transformed/IMM_brut.csv", sep = ";", dec = ",")
head(dat.IMM)
# Remove last column 
dat.IMM <- dat.IMM[, 1:(ncol(dat.IMM)-1)]

# Housing data
dat.LOG <- read.csv("../data/INSEE_transformed/LOG_brut.csv", sep = ";", dec = ",")
head(dat.LOG)
# Remove last column 
dat.LOG <- dat.LOG[, 1:(ncol(dat.LOG)-1)]

# Population data
dat.POP <- read.csv("../data/INSEE_transformed/POP_brut.csv", sep = ";", dec = ",")
head(dat.POP)
# Remove last column 
dat.POP <- dat.POP[, 1:(ncol(dat.POP)-1)]

# Income data
dat.REV <- read.csv("../data/INSEE_transformed/REV_brut.csv", sep = ";", dec = ",")
head(dat.REV)
# Remove last column 
dat.REV <- dat.REV[, 1:(ncol(dat.REV)-1)]

# Types of datasets
dataTypes <- c("ACT", "EMP", "FAM", "FOR", "GEO", "IMM", "LOG", "POP", "REV")

# Merge all predictor data into a single dataset
dat.all <- merge(dat.ACT, dat.EMP, all = TRUE, by = "codgeo")
dat.all <- merge(dat.all, dat.FAM, all = TRUE, by = "codgeo")
dat.all <- merge(dat.all, dat.FOR, all = TRUE, by = "codgeo")
dat.all <- merge(dat.all, dat.GEO, all = TRUE, by = "codgeo")
dat.all <- merge(dat.all, dat.IMM, all = TRUE, by = "codgeo")
dat.all <- merge(dat.all, dat.LOG, all = TRUE, by = "codgeo")
dat.all <- merge(dat.all, dat.POP, all = TRUE, by = "codgeo")
dat.all <- merge(dat.all, dat.REV, all = TRUE, by = "codgeo")
names(dat.all)

# Get names of all the predictors
predNames <- names(dat.all)
predNames <- predNames[-1] # Remove codgeo

# Get classes of all the predictors
predClass <- c(rep("ACT", ncol(dat.ACT)-1), 
               rep("EMP", ncol(dat.EMP)-1),
               rep("FAM", ncol(dat.FAM)-1),
               rep("FOR", ncol(dat.FOR)-1),
               rep("GEO", ncol(dat.GEO)-1),
               rep("IMM", ncol(dat.IMM)-1),
               rep("LOG", ncol(dat.LOG)-1),
               rep("POP", ncol(dat.POP)-1),
               rep("REV", ncol(dat.REV)-1)
               )

# Save names of variables and classes as dictionnary
corrPred <- cbind(varName = predNames, varClass = predClass)
dicPred <- predClass
names(dicPred) <- predNames
  
# Define corresponding colors for the different predictors (by type)
colClass <- brewer.pal(length(unique(predClass)), name = "Set1")
names(colClass) <- unique(predClass)

## Load region information for the different EPCI
regions <- read.csv("../data/geographic/EPCI_composition-communale.csv")
head(regions)
# Create dictionnary 
dic.reg <- regions$REG
names(dic.reg) <- regions$EPCI

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
  out <- 1 * (v <= qval)
  
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
  
  out
}

# For debugging
# clAge <- "00-19"
# varVacc <- "taux_cumu_termine"
# varPred <- "Wk_Res_Municipality"
# thedate <- date1

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

# Add the parameter information
mm <- cbind(parms, output)

names(mm) <- c("clAge", "varVacc", "varPred", "thedate", "N", "estimate", "lower", "upper", "midp.exact", "fisher.exact", "chi.square")

# Save the output
save(mm, file = "output_2021-10-07.RData")



#### PLOT ####
# OR as 1/OR if < 1
mm$OR <- mm$estimate
mm[mm$OR < 1, "OR"] <- 1/mm[mm$OR < 1, "OR"]

tmp <- mm[mm$thedate == date1 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == "TOUT_AGE", ]

plot(tmp$estimate)

plot(-log(tmp$midp.exact, 10))

plot(tmp$OR, -log(tmp$fisher.exact, 10), col = colClass[dicPred[tmp$varPred]], pch = 16)
legend("topleft", legend = names(colClass), col = colClass, pch = 16)

tmp[order(tmp$OR, decreasing = TRUE), c("varPred", "OR")]


clA <- "40-54"
tmp1 <- mm[mm$thedate == date1 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == clA, ]
tmp3 <- mm[mm$thedate == date3 & mm$varVacc == "taux_cumu_1_inj" & mm$clAge == clA, ]

head(tmp1)
plot(tmp1$OR, tmp3$OR, pch = 16, col = colClass[dicPred[tmp$varPred]], 
     xlim = range(c(tmp1$OR, tmp3$OR)), 
     ylim = range(c(tmp1$OR, tmp3$OR)))
abline(a = 0, b = 1)

head(tmp3[order(tmp3$OR, decreasing = TRUE), c("varPred", "OR", 'estimate')])

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
