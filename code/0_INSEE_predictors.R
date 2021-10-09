#### INITIALIZATIONS ####

## PARAMETERS

# Threshold for correlation in the variables
thrCor <- 0.95


## FUNCTIONS

# Function to check correlations
checkCor <- function(dat){
  cor.dat <- cor(dat, use = "pairwise.complete.obs")
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
dat.ACT <- read.csv("../data/INSEE_transformed/ACT_brut.csv", sep = ";", dec = ",")
head(dat.ACT)
# Remove last column 
dat.ACT <- dat.ACT[, 1:(ncol(dat.ACT)-1)]
# Check correlations
cor.ACT <- checkCor(dat.ACT[, -1])
cor.ACT
image(cor.ACT)
heatmap(cor.ACT, Rowv = NA, Colv = NA, cexRow = 0.7, cexCol = 0.7)
# We can remove the following ones
rm.ACT <- c("X15._Men_amg_salWF", "X15._SelfEmployed_amg_nonsalWF")

#---------------------------------------------------------------------------------------
# Employment data
dat.EMP <- read.csv("../data/INSEE_transformed/EMP_brut.csv", sep = ";", dec = ",")
head(dat.EMP)
# Remove last column 
dat.EMP <- dat.EMP[, 1:(ncol(dat.EMP)-1)]
# Check correlations
cor.EMP <- checkCor(dat.EMP[, -1])
cor.EMP
image(cor.EMP)
heatmap(1 * (abs(cor.EMP) > thrCor), cexRow = 0.7, cexCol = 0.7)

network <- graph_from_adjacency_matrix(1 * (abs(cor.EMP) > thrCor), weighted = TRUE, mode="undirected", diag = FALSE)
plot(network, vertex.label.cex=0.7, vertex.size = 6)

# We can remove the following ones
rm.EMP <- c("")

#---------------------------------------------------------------------------------------
# Family data
dat.FAM <- read.csv("../data/INSEE_transformed/FAM_brut.csv", sep = ";", dec = ",")
head(dat.FAM)
# Remove last column 
dat.FAM <- dat.FAM[, 1:(ncol(dat.FAM)-1)]
cor.FAM <- checkCor(dat.FAM[, -1])
heatmap(1 * (abs(cor.FAM) > thrCor), cexRow = 0.7, cexCol = 0.7)

network <- graph_from_adjacency_matrix(1 * (abs(cor.FAM) > thrCor), weighted = TRUE, mode="undirected", diag = FALSE)
plot(network, vertex.label.cex=0.7, vertex.size = 6)

#---------------------------------------------------------------------------------------
# Education data
dat.FOR <- read.csv("../data/INSEE_transformed/FOR_brut.csv", sep = ";", dec = ",")
head(dat.FOR)
# Remove last column 
dat.FOR <- dat.FOR[, 1:(ncol(dat.FOR)-1)]
# Check correlations
cor.FOR <- checkCor(dat.FOR[, -1])
heatmap(1 * (abs(cor.FOR) > thrCor), cexRow = 0.7, cexCol = 0.7)

network <- graph_from_adjacency_matrix(1 * (abs(cor.FOR) > thrCor), weighted = TRUE, mode="undirected", diag = FALSE)
plot(network, vertex.label.cex=0.7, vertex.size = 6)

#---------------------------------------------------------------------------------------
# Geographic data
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

#---------------------------------------------------------------------------------------
# Immigration data 
dat.IMM <- read.csv("../data/INSEE_transformed/IMM_brut.csv", sep = ";", dec = ",")
head(dat.IMM)
# Remove last column 
dat.IMM <- dat.IMM[, 1:(ncol(dat.IMM)-1)]
# Check correlations
cor.IMM <- checkCor(dat.IMM[, -1])
cor.IMM
heatmap(1 * (abs(cor.IMM) > thrCor), cexRow = 0.7, cexCol = 0.7)

network <- graph_from_adjacency_matrix(1 * (abs(cor.IMM) > thrCor), weighted = TRUE, mode="undirected", diag = FALSE)
plot(network, vertex.label.cex=0.7, vertex.size = 6)

#---------------------------------------------------------------------------------------
# Housing data
dat.LOG <- read.csv("../data/INSEE_transformed/LOG_brut.csv", sep = ";", dec = ",")
head(dat.LOG)
# Remove last column 
dat.LOG <- dat.LOG[, 1:(ncol(dat.LOG)-1)]
# Check correlations
cor.LOG <- checkCor(dat.LOG[, -1])
heatmap(1 * (abs(cor.LOG) > thrCor), cexRow = 0.7, cexCol = 0.7)

network <- graph_from_adjacency_matrix(1 * (abs(cor.LOG) > thrCor), weighted = TRUE, mode="undirected", diag = FALSE)
plot(network, vertex.label.cex=0.7, vertex.size = 6)

#---------------------------------------------------------------------------------------
# Population data
dat.POP <- read.csv("../data/INSEE_transformed/POP_brut.csv", sep = ";", dec = ",")
head(dat.POP)
# Remove last column 
dat.POP <- dat.POP[, 1:(ncol(dat.POP)-1)]
# Check correlations
cor.POP <- checkCor(dat.POP[, -1])
heatmap(1 * (abs(cor.POP) > thrCor), cexRow = 0.7, cexCol = 0.7)

network <- graph_from_adjacency_matrix(1 * (abs(cor.POP) > thrCor), weighted = TRUE, mode="undirected", diag = FALSE)
plot(network, vertex.label.cex=0.7, vertex.size = 6)

#---------------------------------------------------------------------------------------
# Income data
dat.REV <- read.csv("../data/INSEE_transformed/REV_brut.csv", sep = ";", dec = ",")
head(dat.REV)
# Remove last column 
dat.REV <- dat.REV[, 1:(ncol(dat.REV)-1)]
# Check correlations
cor.REV <- checkCor(dat.REV[, -1])
heatmap(1 * (abs(cor.REV) > thrCor), cexRow = 0.7, cexCol = 0.7)

network <- graph_from_adjacency_matrix(1 * (abs(cor.REV) > thrCor), weighted = TRUE, mode="undirected", diag = FALSE)
plot(network, vertex.label.cex=0.7, vertex.size = 6)

#---------------------------------------------------------------------------------------

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


#### Check correlations ####
## Check correlations
# Get all pairwise correlations
corINSEE <- cor(dat.all[, -1], use = "pairwise.complete.obs")
# Select those above threshold
corINSEE2 <- 1 * (abs(corINSEE) > thrCor)
# Remove diagonal
diag(corINSEE2) <- NA

keep <- (rowSums(corINSEE2, na.rm = TRUE) > 0)
keep

corINSEE2.reduced <- corINSEE2[keep, keep]
dim(corINSEE2.reduced)

image(corINSEE2.reduced)
par(mar = rep(7, 4))
hm <- heatmap(corINSEE2.reduced, keep.dendro = FALSE)
hm




#install.packages("igraph")

corlist <- which(corINSEE2.reduced > 0, arr.ind = TRUE)
dim(corlist)

write.csv(cbind(row.names(corINSEE2.reduced)[corlist[, 1]], 
                row.names(corINSEE2.reduced)[corlist[, 2]], 
                c(corINSEE2.reduced[corlist])), "tmp.csv")



rn <- row.names(corINSEE2.reduced)[hm$rowInd]
corINSEE3 <- cor(dat.all[, rn], use = "pairwise.complete.obs")
diag(corINSEE3) <- NA

corlist3 <- which(abs(corINSEE3) > thrCor, arr.ind = TRUE)
dim(corlist3)

write.csv(cbind(row.names(corINSEE3)[corlist3[, 1]], 
                row.names(corINSEE3)[corlist3[, 2]], 
                c(corINSEE3[corlist3])), "tmp3.csv")


length(corINSEE2.reduced[unname(corlist)])

corlist

# Make an Igraph object from this matrix:
network <- graph_from_adjacency_matrix(corINSEE2, weighted = TRUE, mode="undirected", diag = FALSE)

# Basic chart
plot(network)

sum(corINSEE2, na.rm = TRUE)

diffsupercor <- supercor[supercor[, 1] > supercor[, 2], ]
nrow(diffsupercor)
diffsupercor


unique(row.names(diffsupercor))

?which
corINSEE[cor]
row.names(corINSEE)
image(corINSEE)

###--------------------------

# Define corresponding colors for the different predictors (by type)
colClass <- brewer.pal(length(unique(predClass)), name = "Set1")
names(colClass) <- unique(predClass)

## Load region information for the different EPCI
regions <- read.csv("../data/geographic/EPCI_composition-communale.csv")
head(regions)
# Create dictionnary 
dic.reg <- regions$REG
names(dic.reg) <- regions$EPCI