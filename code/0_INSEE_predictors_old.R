#### INITIALIZATIONS ####

# Project is at the root; change wd to code/ if not already in there
if(!file.exists("0_INSEE_predictors.R")){
  setwd("code/")
}

checkCorrelations <- FALSE # Whether to check correlations in the data

## PARAMETERS

library("RColorBrewer")

# Threshold for correlation in the variables
thrCor <- 0.95

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

#---------------------------------------------------------------------------------------
# Activity data
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

# Structure is then the same as for ACT, so not commented in detail

#---------------------------------------------------------------------------------------
# Employment data
system("diff ../data/INSEE_transformed/EMP_brut.csv ../data/EMP_brut.csv")
dat.EMP <- read.csv("../data/EMP_brut.csv")
head(dat.EMP)
dat.EMP <- dat.EMP[, -which(is.element(names(dat.EMP), "taux_cumu_1_inj"))]
any(duplicated(names(dat.EMP)))

#---------------------------------------------------------------------------------------
# Family data
system("diff ../data/INSEE_transformed/FAM_brut.csv ../data/FAM_brut.csv")
dat.FAM <- read.csv("../data/FAM_brut.csv")
head(dat.FAM)
dat.FAM <- dat.FAM[, -which(is.element(names(dat.FAM), "taux_cumu_1_inj"))]
any(duplicated(names(dat.FAM)))

#---------------------------------------------------------------------------------------
# Education data
system("diff ../data/INSEE_transformed/FOR_brut.csv ../data/FOR_brut.csv")
dat.FOR <- read.csv("../data/FOR_brut.csv")
head(dat.FOR)
dat.FOR <- dat.FOR[, -which(is.element(names(dat.FOR), "taux_cumu_1_inj"))]
any(duplicated(names(dat.FOR)))

#---------------------------------------------------------------------------------------
# Geographic data
# system("diff ../data/geographic/exportGeo_EPCI.csv ../data/GEO_brut.csv")
dat.GEO <- read.csv("../data/GEO_brut.csv")
head(dat.GEO)
dat.GEO <- dat.GEO[, -which(is.element(names(dat.GEO), c("taux_cumu_1_inj", "lat01", "lon01")))]
any(duplicated(names(dat.GEO)))

#---------------------------------------------------------------------------------------
# Immigration data 
system("diff ../data/INSEE_transformed/IMM_brut.csv ../data/IMM_brut.csv")
dat.IMM <- read.csv("../data/IMM_brut.csv")
head(dat.IMM)
dat.IMM <- dat.IMM[, -which(is.element(names(dat.IMM), "taux_cumu_1_inj"))]
any(duplicated(names(dat.IMM)))

#---------------------------------------------------------------------------------------
# Housing data
system("diff ../data/INSEE_transformed/LOG_brut.csv ../data/LOG_brut.csv")
dat.LOG <- read.csv("../data/LOG_brut.csv")
head(dat.LOG)
dat.LOG <- dat.LOG[, -which(is.element(names(dat.LOG), "taux_cumu_1_inj"))]
any(duplicated(names(dat.LOG)))

#---------------------------------------------------------------------------------------
# Population data
system("diff ../data/INSEE_transformed/POP_brut.csv ../data/POP_brut.csv")
dat.POP <- read.csv("../data/POP_brut.csv")
head(dat.POP)
dat.POP <- dat.POP[, -which(is.element(names(dat.POP), "taux_cumu_1_inj"))]
any(duplicated(names(dat.POP)))

#---------------------------------------------------------------------------------------
# Income data
system("diff ../data/INSEE_transformed/REV_brut.csv ../data/REV_brut.csv")
dat.REV <- read.csv("../data/REV_brut.csv")
head(dat.REV)
dat.REV <- dat.REV[, -which(is.element(names(dat.REV), "taux_cumu_1_inj"))]
any(duplicated(names(dat.REV)))

#---------------------------------------------------------------------------------------
# Election data
dat.PRE <- read.csv("../data/PRE_brut.csv")
head(dat.PRE)
any(duplicated(names(dat.PRE)))

#---------------------------------------------------------------------------------------

# Types of datasets
dataTypes <- c("ACT", "EMP", "FAM", "FOR", "GEO", "IMM", "LOG", "POP", "REV", "PRE")

# Merge all predictor data into a single dataset
# Initialize the merge
dat.all <- merge(dat.ACT, dat.EMP, all = TRUE, by = "codgeo")
# Continue with the other datasets
for(suffix in dataTypes[3:length(dataTypes)]){
  dat.all <- merge(dat.all, get(paste0("dat.", suffix)), all = TRUE, by = "codgeo")
}

dim(dat.all)
# Sanity check: compute sum of numbers of columns, 
#               removing the codgeo column for all but one dataset (hence -1, and +1)
sum(vapply(dataTypes, function(i) ncol(get(paste0("dat.", i))) - 1, 1)) + 1


# Get names of all the predictors
predNames <- names(dat.all)
predNames <- predNames[-1] # Remove codgeo

# Get classes of all the predictors
# Initialize the vector
predClass <- c()
# Add the name of the type of data, repeated the number of columns - 1 (-1 for codgeo)
for(suffix in dataTypes){
  predClass <- c(predClass, rep(suffix, ncol(get(paste0("dat.", suffix))) - 1))
}
predClass

# Save names of variables and classes as dictionary
corrPred <- cbind(varName = predNames, varClass = predClass)
dicPred <- predClass
names(dicPred) <- predNames


#### CHECK CORRELATIONS ####

## Check correlations
# Get all pairwise correlations
cormat <- cor(dat.all[, -1], use = "pairwise.complete.obs")
diag(cormat) <- NA # Remove diagonal

print(paste("thrCor = ", thrCor))
# Identify correlations greater or equal than the defined threshold
tmp <- which(cormat >= thrCor, arr.ind = TRUE)

# Keep only half (the other half are duplicates)
triangle <- tmp[tmp[, 1] <= tmp[, 2], ]

# Sanity check
c(nrow(tmp)/2, nrow(triangle))

# Remove the duplicates
#   Get the names of the correlated columns
correlated <- unique(colnames(cormat)[triangle[, 2]])
#   Get their indices (col positions)
i.corr <-   which(is.element(names(dat.all), correlated))
#   Remove them
dat.nocorr <- dat.all[, -i.corr]

dim(dat.nocorr)

if(checkCorrelations){
  ## Check correlations
  # Get all pairwise correlations
  cormat <- cor(dat.all[, -1], use = "pairwise.complete.obs")
  diag(cormat) <- NA # Remove diagonal
  
  # Select those above threshold
  cormat2 <- 1 * (abs(cormat) > thrCor)
  # Remove diagonal
  diag(cormat2) <- NA
  
  # Identify the indices of the variables that are correlated with another one
  keep <- (rowSums(cormat2, na.rm = TRUE) > 0)
  # Subset the correlation matrix, keeping only lines with correlations
  cormat2.reduced <- cormat2[keep, keep]
  
  hm <- heatmap(cormat2.reduced, keep.dendro = FALSE)
  hm
  
  # Function to plot heatmap from a table of variables
  plotCorHeatmap <- function(cols2remove, thr = thrCor){
    # cordat correlation matrix
    # thrCor threshold correlation
    
    # Indices of the variables to remove
    inds2remove <- which(is.element(row.names(cormat2.reduced), cols2remove))
    
    print(inds2remove)
    # Remove lines and columns of these indices
    mm <- subset(cormat2.reduced, select = - inds2remove)[- inds2remove, ]
    
    # Identify the indices of the variables that are correlated with another one
    keep <- (rowSums(mm, na.rm = TRUE) > 0)
    
    # Remove line if no correlation anymore
    print(dim(mm[keep, keep]))
    hm <- heatmap(mm[keep, keep], cexRow = 0.6)
    print(row.names(mm[keep, keep][hm$rowInd, hm$colInd]))
  }
  
  # This vector was done sequentially, 
  # by plotting the correlation matrix and removing correlated variables
  rmVar <- c("X5564_men_Workforce_rate", 
             "X1524_men_Workforce_rate", 
             "X5564_Employed_rate_amg_WF", 
             "X1564_BlueCollar_amg_EmpWF", 
             "X15._women_amg_empWF", 
             "X15._FullTime_amg_salWF", 
             "X15._women_amg_nonsalWF", 
             "SingleMan_HH", 
             "OtherNoFamily_HH", 
             "ChildFamily_HH", 
             "WhiteCollar_HH", 
             "Other_HH", 
             "CraftsBusinessShopkeepers_HH", 
             "X1524_amg_15.POP", 
             "X15._Married_amg_POP", 
             "X2ry_res", 
             "X1ry_res_gt0car", 
             "Pop_per_1ry_res_Owner", 
             "X90._women_amg_wPOP", 
             "X15._women_OtherNoActivity_amg_wPOP", 
             "X15._men_CraftsBusinessShopkeeper_amg_mPOP", 
             "Activity_Income", 
             "X1524_men_Employed_rate_amg_WF", 
             "X1524_Employed_rate_amg_WF", 
             "SingleParent_HH",
             "Single_Parent_Family_amg_HH", 
             "X15._Employers_amg_nonsalWF", 
             "X15._men_NoDiploma_amg_mWF", 
             "X15._women_NoDiploma_amg_wWF", 
             "X15._men_VocationalGraduate_amg_mWF", 
             "X15._women_VocationalGraduate_amg_wWF", 
             "X4559_men_amg_mPOP",
             "X4559_women_amg_wPOP",
             "X2064_men_amg_mPOP", 
             "X2064_women_amg_wPOP", 
             "X15._Men_amg_salWF", 
             "X15._Women_amg_salWF", 
             "X15._women_amg_salWF", 
             "X3044_men_amg_mPOP", 
             "X3044_wommen_amg_mPOP", 
             "SingleWoman_HH", 
             "Social_Minima" ,
             "Housing_Benef", 
             "Family_HH", 
             "Family_wo_Children_amg_HH", 
             "Family_w_Children_amg_HH", 
             "NoChildFamily_HH", 
             "SinglePerson_HH", 
             "Intermediate_HH", 
             "X15._men_BlueCollar_amg_mPOP", 
             "X15._BlueCollar_amg_POP",
             "BlueCollar_HH", 
             "X15._IntermediateProf_amg_POP", 
             "X15._women_IntermediateProf_amg_wPOP", 
             "Flat_1ry_res", 
             "House_1ry_res", 
             "Houses", 
             "X15._HSG.4_amg_WF", 
             "X3039_Poverty", 
             "X5059_Poverty", 
             "X4049_Poverty", 
             "X2554_amg_15.POP", 
             "X3044_women_amg_wPOP", 
             "X15._men_amg_FullTimeWF", 
             "X15._Salaried_amg_empWF", 
             "X15._women_amg_FullTimeWF", 
             "X15._women_Farmers_amg_wPOP",                     
             "X15._men_Farmers_amg_mPOP",                      
             "X1564_Farmers_amg_WF",                         
             "X1564_Farmers_amg_EmpWF",                        
             "Farmer_HH",                                      
             "X15._Farmers_amg_POP", 
             "Owners_Occupancy", 
             "FreeAcc_Occupancy", 
             "X1ry_res_Occupancy", 
             "X1564_Employed_rate_amg_WF",                     
             "X2554_Employed_rate_amg_WF", 
             "X1564_women_Employed_rate_amg_WF", 
             "X2554_women_Employed_rate_amg_WF", 
             "X1564_men_Employed_rate_amg_WF", 
             "X2554_men_Employed_rate_amg_WF", 
             "X15._men_ManagersHigherIntellectProf_amg_mPOP", 
             "X15._ManagersHigherIntellectProf_amg_POP",
             "X1564_HihgQualWorkers_amg_EmpWF", 
             "HighQualidied_HH", 
             "X1564_NonWorking_amg_WF", 
             "X2554_amg_HH", 
             "X15._men_HighEducation_amg_mWF", 
             "X7589_men_amg_mPOP", 
             "X7589_women_amg_wPOP", 
             "X80._amg_HH", 
             "X65._women_amg_wPOP", 
             "Immigrant_amg_Women", 
             "Stranger_amg_Women",                             
             "French_nlty_amg_Women",                          
             "Immigrant_amg_Men",                              
             "Stranger_amg_Men",                               
             "French_nlty_amg_Men",                            
             "Immigrant",                                      
             "French_nlty", 
             "X5579_amg_HH", 
             "X6074_men_amg_mPOP", 
             "X65._men_amg_mPOP", 
             "X6074_women_amg_wPOP", 
             "X0014_women_amg_wPOP", 
             "X0014_men_amg_mPOP", 
             "X0019_women_amg_wPOP", 
             "X0019_men_amg_mPOP", 
             "X15._women_Retired_amg_wPOP", 
             "Retired_HH", 
             "X15._Retired_amg_POP", 
             "X2554_Unemployed_rate_amg_WF", 
             "X1564_men_Unemplyed_amg_WF", 
             "X1564_women_Unemplyed_amg_WF", 
             "X7589_amg_POP", 
             "X0019_amg_POP", 
             "X15._women_HighEducation_amg_wWF", 
             "X15._HSG.5._amg_WF", 
             "X15._HighEducation_amg_WF", 
             "X15._women_ManagersHigherIntellectProf_amh_wPOP", 
             "Tenant_Occupancy", 
             "X5579_amg_15.POP", 
             "X15._men_Retired_amg_mPOP", 
             "X65._amg_POP"
  )
  plotCorHeatmap(rmVar)
  
  dat.all.original <- dat.all
  
  indsKeep <- which(!is.element(names(dat.all), rmVar))
  
  #dat.all <- dat.all[, c(indsKeep)]
  
  # Restrict the dictionary of predictor classes to the ones we kept
  dicPred <- dicPred[names(dat.all[, -1])]
  
}

###--------------------------

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

# Export the result
save(dat.all, dicPred, colClass, file = "../data/predictors.RData")

