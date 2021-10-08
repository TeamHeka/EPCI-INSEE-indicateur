# Load EPCI information
epci.info <- read.csv("../data/geographic/EPCI_composition-communale.csv")
# Turn into dico
comm <- epci.info$EPCI
names(comm) <- as.character(epci.info$CODGEO)

# Load arrondissement information
arr.info <- read.csv("../data/geographic/arrondissement2021.csv")
head(arr.info)
arr.info$codeEPCI <- comm[as.character(arr.info$CHEFLIEU)]

# Append to our dictionnary
comm <- c(epci.info$EPCI, arr.info$codeEPCI)
names(comm) <- c(as.character(epci.info$CODGEO), as.character(arr.info$ARR))


arr.info[arr.info$ARR == "75110", ]

# Load Communes information
vaccCom <- read.csv("../data/ameli_vaccination/vaccCom.csv", sep = ";")
names(vaccCom)[c(3, 4)] <- c("codgeo", "libelle_geo")


unique(vaccCom$codgeo)
vaccCom$epci <- comm[as.character(vaccCom$codgeo)]
vaccCom$epci


head(vaccCom)
unique(vaccCom$codgeo)
