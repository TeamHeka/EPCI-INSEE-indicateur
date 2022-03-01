# Load vaccination data
#
# The files are downloaded by running "0_loadAmeliData.R"
#

### EPCI ####

# Load dataset 
vaccEPCI <- read.csv("../data/ameli_vaccination/vaccEPCI.csv", sep = ";")
head(vaccEPCI)

# Load region information for the different EPCI
regions <- read.csv("../data/geographic/EPCI_composition-communale.csv")
head(regions)
# Create dictionary 
dic.reg <- regions$REG
names(dic.reg) <- regions$EPCI

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


### Communes ####

# Load dataset
vaccCom <- read.csv("../data/ameli_vaccination/vaccCom.csv", sep = ";")
head(vaccCom)
# Rename some fields for future merging
names(vaccCom)[c(3, 4)] <- c("codgeo", "libelle_geo")

### Merge into a single dataset ####

vacc <- rbind(vaccEPCI[, 1:16], vaccCom)

# Clean memory
rm(vaccCom, vaccEPCI)

# Make sure that population sizes are numeric
vacc$population_carto <- as.numeric(vacc$population_carto)

# Clean up ages
vacc <- vacc[which(!is.element(vacc$classe_age, c("", NA))), ]


## Compute France population data ####

# Compute proportions of the different age classes in the French population

# Compute population distribution in France
thedate <- "2021-07-11" # a random date
# Subset of the data at that date, excluding TOUT_AGE
sub <- vacc[which(vacc$date == thedate & vacc$classe_age != "TOUT_AGE"), ]

# Compute sums per age class
distAge <- aggregate(sub$population_carto, by = list(classe_age = sub$classe_age), FUN = sum)
totPop <- sum(distAge$x) # Total population size
totPop
# Compute proportions
distAge$p <- distAge$x / totPop

# Rewrite age as factor
distAge$age.f <- as.factor(distAge$classe_age)

## Some useful quantities ####

# Vector of ages
ages <- sort(unique(vacc$classe_age))
ages <- ages[ages != "TOUT_AGE"]
