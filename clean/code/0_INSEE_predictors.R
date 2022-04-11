#### INITIALIZATIONS ####
#library("RColorBrewer")

# Project is at the root; change wd to code/ if not already in there
if(!file.exists("0_INSEE_predictors.R")){
  setwd("code/")
}

sortData <- FALSE

## PARAMETERS 

# Threshold for correlation in the variables
# Variables with absolute correlation above this threshold are removed from the analysis
thrCor <- 0.9

# Threshold for missing values
# We will not consider variables with more than this threshold of missing values
thrMissingVals <- 0.05

## FUNCTIONS

# Function to check correlations
checkCor <- function(dat){
  # Compute correlations
  cor.dat <- cor(dat, use = "pairwise.complete.obs")
  # Set diagonal to NA (variance)
  diag(cor.dat) <- NA
  # Turn into binary depending on position wrt threshold
  cor.dat2 <- 1*(abs(cor.dat) > thrCor)
  # Remove diagonal
  diag(cor.dat2) <- 0
  print(sum(cor.dat2))
  
  # Trim table to only show lines with correlations
  rs <- rowSums(cor.dat2)
  keep <- (rs > 0)
  cor.dat[keep, keep] # Output
}

#### LOAD INSEE AND GEO DATA ####

# Initialize the dataType vector. It will contain information on the classes
dataType <- data.frame(predName = c(), predType = c())

# Activity data ---------------------------------------------------------------------------------------
# Check if there are differences in the two versions of the data file
system("diff ../data/INSEE_transformed/ACT_brut.csv ../data/ACT_brut.csv")
# Loaf the data
dat.ACT <- read.csv("../data/ACT_brut.csv")
dim(dat.ACT)
head(dat.ACT)
# Remove vaccination data
dat.ACT <- dat.ACT[, -which(is.element(names(dat.ACT), "taux_cumu_1_inj"))]
# Check duplicates in names
any(duplicated(names(dat.ACT)))
# Add information to the dataType vector
dataType <- rbind(dataType, data.frame(predName = names(dat.ACT)[-1], predType = "ACT"))


# Structure is then the same as for ACT, so not commented in detail

# Employment data ---------------------------------------------------------------------------------------
system("diff ../data/INSEE_transformed/EMP_brut.csv ../data/EMP_brut.csv")
dat.EMP <- read.csv("../data/EMP_brut.csv")
head(dat.EMP)
dat.EMP <- dat.EMP[, -which(is.element(names(dat.EMP), "taux_cumu_1_inj"))]
any(duplicated(names(dat.EMP)))
dataType <- rbind(dataType, data.frame(predName = names(dat.EMP)[-1], predType = "EMP"))

# Family data ---------------------------------------------------------------------------------------
system("diff ../data/INSEE_transformed/FAM_brut.csv ../data/FAM_brut.csv")
dat.FAM <- read.csv("../data/FAM_brut.csv")
head(dat.FAM)
dat.FAM <- dat.FAM[, -which(is.element(names(dat.FAM), "taux_cumu_1_inj"))]
any(duplicated(names(dat.FAM)))
dataType <- rbind(dataType, data.frame(predName = names(dat.FAM)[-1], predType = "FAM"))

# Education data ---------------------------------------------------------------------------------------
system("diff ../data/INSEE_transformed/FOR_brut.csv ../data/FOR_brut.csv")
dat.FOR <- read.csv("../data/FOR_brut.csv")
head(dat.FOR)
dat.FOR <- dat.FOR[, -which(is.element(names(dat.FOR), "taux_cumu_1_inj"))]
any(duplicated(names(dat.FOR)))
dataType <- rbind(dataType, data.frame(predName = names(dat.FOR)[-1], predType = "FOR"))

# Geographic data ---------------------------------------------------------------------------------------
# system("diff ../data/geographic/exportGeo_EPCI.csv ../data/GEO_brut.csv")
# Computed in `geographic.R`
dat.GEO <- read.csv("../data/GEO_brut.csv")
head(dat.GEO)
dat.GEO <- dat.GEO[, -which(is.element(names(dat.GEO), c("taux_cumu_1_inj", "lat01", "lon01")))]
any(duplicated(names(dat.GEO)))
dataType <- rbind(dataType, data.frame(predName = names(dat.GEO)[-1], predType = "GEO"))

# Immigration data ---------------------------------------------------------------------------------------
system("diff ../data/INSEE_transformed/IMM_brut.csv ../data/IMM_brut.csv")
dat.IMM <- read.csv("../data/IMM_brut.csv")
head(dat.IMM)
dat.IMM <- dat.IMM[, -which(is.element(names(dat.IMM), "taux_cumu_1_inj"))]
any(duplicated(names(dat.IMM)))
dataType <- rbind(dataType, data.frame(predName = names(dat.IMM)[-1], predType = "IMM"))

# Housing data ---------------------------------------------------------------------------------------
system("diff ../data/INSEE_transformed/LOG_brut.csv ../data/LOG_brut.csv")
dat.LOG <- read.csv("../data/LOG_brut.csv")
head(dat.LOG)
dat.LOG <- dat.LOG[, -which(is.element(names(dat.LOG), "taux_cumu_1_inj"))]
any(duplicated(names(dat.LOG)))
dataType <- rbind(dataType, data.frame(predName = names(dat.LOG)[-1], predType = "LOG"))

# Population data ---------------------------------------------------------------------------------------
system("diff ../data/INSEE_transformed/POP_brut.csv ../data/POP_brut.csv")
dat.POP <- read.csv("../data/POP_brut.csv")
head(dat.POP)
dat.POP <- dat.POP[, -which(is.element(names(dat.POP), "taux_cumu_1_inj"))]
any(duplicated(names(dat.POP)))
dataType <- rbind(dataType, data.frame(predName = names(dat.POP)[-1], predType = "POP"))

# Income data ---------------------------------------------------------------------------------------
system("diff ../data/INSEE_transformed/REV_brut.csv ../data/REV_brut.csv")
dat.REV <- read.csv("../data/REV_brut.csv")
head(dat.REV)
dat.REV <- dat.REV[, -which(is.element(names(dat.REV), "taux_cumu_1_inj"))]
any(duplicated(names(dat.REV)))
dataType <- rbind(dataType, data.frame(predName = names(dat.REV)[-1], predType = "REV"))

# Election data ---------------------------------------------------------------------------------------
dat.PRE <- read.csv("../data/PRE_brut.csv")
head(dat.PRE)
any(duplicated(names(dat.PRE)))
dataType <- rbind(dataType, data.frame(predName = names(dat.PRE)[-1], predType = "PRE"))

#### MERGE DATASETS ####
# Types of datasets
dataTypes <- c("ACT", "REV", "FOR", "EMP", "IMM", "LOG", "FAM", "POP", "PRE", "GEO")

# Merge all predictor data into a single dataset
# Initialize the merge
dat.all <- merge(dat.ACT, dat.REV, all = TRUE, by = "codgeo")
# Continue with the other datasets
for(suffix in dataTypes[3:length(dataTypes)]){
  dat.all <- merge(dat.all, get(paste0("dat.", suffix)), all = TRUE, by = "codgeo")
}

dim(dat.all)
# Sanity check: compute sum of numbers of columns, 
#               removing the codgeo column for all but one dataset (hence -1, and +1)
sum(vapply(dataTypes, function(i) ncol(get(paste0("dat.", i))) - 1, 1)) + 1


if(sortData){
  # Sort columns by alphabetical order
  # +1 not to be forgotten: indices did not include the first column
  nn <- names(dat.all)[2:ncol(dat.all)]
  dat.all <- dat.all[, c(1, order(nn) + 1)]
}


#### CHECK MISSING VALUES ####

# Count missing values
missingvals <- apply(dat.all, 2, function(x) sum(is.na(x)))
propMissingVals <- missingvals / nrow(dat.all)
  
# Show them
sort(round(propMissingVals, 4), decreasing = TRUE)

dat.removeMissing <- dat.all[, which(propMissingVals <= thrMissingVals)]

dim(dat.all)
dim(dat.removeMissing)

#### CHECK CORRELATIONS ####

## Check correlations
# Get all pairwise correlations
# and take absolute value
cormat <- abs(cor(dat.removeMissing[, -1], use = "pairwise.complete.obs"))
diag(cormat) <- NA # Remove diagonal

# Sanity check
all(rownames(cormat) == colnames(cormat))

# indices to sort in alphabetical order
ialph <- order(rownames(cormat))

ocormat <- cormat
cormat <- cormat[ialph, ialph]

print(paste("thrCor = ", thrCor))
# Identify indices of the correlations greater or equal than the defined threshold
indOverThr <- which(cormat >= thrCor, arr.ind = TRUE)

# Keep only half (the other half are duplicates)
triangle <- indOverThr[indOverThr[, 1] <= indOverThr[, 2], ]

# Sanity check
stopifnot(nrow(indOverThr)/2 == nrow(triangle))

# Remove the duplicates
#   Get the names of the correlated columns
correlated <- unique(colnames(cormat)[triangle[, 2]])
#   Get their indices (col positions)
i.corr <-   which(is.element(names(dat.removeMissing), correlated))
#   Remove them
dat.nocorr <- dat.removeMissing[, -i.corr]

dim(dat.nocorr)

# Print names of the removed columns
names(dat.removeMissing)[i.corr]

# Sanity check
all(sort(names(dat.removeMissing)[i.corr]) == sort(correlated))

# Print names of the columns we keep
sort(names(dat.nocorr))

dim(dat.nocorr)

# Get names of all the predictors
predNames <- names(dat.removeMissing)
predNames <- predNames[-1] # Remove codgeo

#............................................................................

#### CLASSES OF THE PREDICTORS ####

## Abundances per type
# All data, distribution
aggregate(dataType$predName, by = list(dataType$predType), FUN = length)

dT2 <- dataType[is.element(dataType$predName, names(dat.nocorr)), ]
aggregate(dT2$predName, by = list(dT2$predType), FUN = length)

## Construct dictionnary
dicPred <- dataType$predType
names(dicPred) <- dataType$predName

# Write down full name of the different classes
dic.fullpred <- c("Activity", "Income", "Education", "Employment", "Immigration", "Housing", "Family", "Population", "Elections", "Geography")
names(dic.fullpred) <- c("ACT", "REV", "FOR", "EMP", "IMM", "LOG", "FAM", "POP", "PRE", "GEO")
dic.fullpred

# Dictionary to sort by type
dic.order <- 1:length(dic.fullpred)
names(dic.order) <- names(dic.fullpred)

# Define corresponding colors for the different predictors (by type)
# From https://medialab.github.io/iwanthue/
# "Pimp" palette
colClass <- c("#9548ce", 
              "#57a741", 
              "#c74795",
              "#437338",
              "#716ab7",
              "#8e8835",
              "#d54b36", 
              "#2da0a1",
              "#ac4d5e",
              "#ae6e32") 
#brewer.pal(length(unique(dicPred)), name = "Set2")
names(colClass) <- unique(dicPred)

#### SORT THE DATA AND EXPORT ####

# Get names of the predictors in the nocorr dataset
nn <- names(dat.nocorr)[-1]
# Get associated types
tt <- dicPred[nn]
# Get associated number, chosen to sort them
tt2 <- dic.order[tt]

# Sanity check
table(tt)
table(tt2)

# Indices of the data, when sorted by type and them alphabetically within type
i.ordered <- order(tt2, nn)

nn[i.ordered]

if(sortData){
  # Reorder the data; 
  #  +1 is here because we have removed codgeo from nn, but indices need to take it into account
  dat.nocorr <- dat.nocorr[, c(1, i.ordered + 1)]
}


# Export the result
save(dat.all, dat.nocorr, dicPred, dic.fullpred, colClass, file = "../data/predictors.RData")

typesDataAll <- table(dic.fullpred[dicPred[names(dat.all[, -1])]])
typesDataNoCorr <- table(dic.fullpred[dicPred[names(dat.nocorr[, -1])]])

sum(typesDataNoCorr[!is.element(names(typesDataNoCorr), c("Geography", "Elections"))])

tb <- typesDataNoCorr[!is.element(names(typesDataNoCorr), c("Geography", "Elections"))]
for(i in 1:length(tb)) cat(paste0(names(tb)[i], ": n = ", tb[i], "; "))


names(dat.nocorr[, -1])[dic.fullpred[dicPred[names(dat.nocorr[, -1])]] == "Geography"]
names(dat.all[, -1])[dic.fullpred[dicPred[names(dat.all[, -1])]] == "Geography"]

names(dat.nocorr[, -1])[dic.fullpred[dicPred[names(dat.nocorr[, -1])]] == "Elections"]
names(dat.all[, -1])[dic.fullpred[dicPred[names(dat.all[, -1])]] == "Elections"]

save(thrCor, thrMissingVals, typesDataAll, typesDataNoCorr, file = "data_indicators.RData")

