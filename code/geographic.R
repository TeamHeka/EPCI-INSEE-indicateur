#### INITIALIZATIONS ####
# Global data: vacc
stopifnot(exists("vacc"))
stopifnot(exists("vaccCom"))
stopifnot(exists("vaccEPCI"))
# They are loaded in florence.Rmd

#### LOAD AND CLEAN GEOGRAPHIC DATA ####
# Source of the two datasets: https://datavaccin-covid.ameli.fr/explore/?sort=modified

#   Source: https://datavaccin-covid.ameli.fr/explore/dataset/georef-france-commune-arrondissement-municipal/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=%3B
geoCom <- read.csv("../data/geographic/fromAmeli/georef-france-commune-arrondissement-municipal.csv",row.names = NULL, sep = ";")
geoCom <- geoCom[, -which(colnames(geoCom) == "Geo.Shape")]

#  Source: https://datavaccin-covid.ameli.fr/explore/dataset/georef-france-epci/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=%3B
geoEPCI <- read.csv("../data/geographic/fromAmeli/georef-france-epci.csv",row.names = NULL, sep = ";")
geoEPCI <- geoEPCI[, -which(colnames(geoEPCI) == "Geo.Shape")]
geoEPCI <- geoEPCI[, -which(colnames(geoEPCI) == "viewport")]

# Extract latitude and longitude from the Geo.Point column
tmpCom <- matrix(unlist(strsplit(geoCom$Geo.Point, ",")), byrow = TRUE, ncol = 2)
geoCom$latitude <- as.numeric(tmpCom[, 1])
geoCom$longitude <- as.numeric(tmpCom[, 2])

tmpEPCI <- matrix(unlist(strsplit(geoEPCI$Geo.Point, ",")), byrow = TRUE, ncol = 2)
geoEPCI$latitude <- as.numeric(tmpEPCI[, 1])
geoEPCI$longitude <- as.numeric(tmpEPCI[, 2])

#### MERGE WITH CODGEO ####

# Check whether codgeo is found in the data

## Communes
mean(is.element(unique(vaccCom$codgeo), as.numeric(geoCom$Code.Officiel.Commune...Arrondissement.Municipal)))
mean(is.element(unique(vaccCom$codgeo), as.numeric(geoCom$Code.Officiel.Commune)))
mean(is.element(unique(vaccCom$codgeo), as.numeric(geoCom$Code.Officiel.Courant.Commune...Arrondissement.Municipal)))

iii <- which(!is.element(unique(vaccCom$codgeo), as.numeric(geoCom$Code.Officiel.Courant.Commune...Arrondissement.Municipal)))
unique(vaccCom$codgeo)[iii]
# The ones that are not found are the ones for which information was missing (generic names to say it is the locality, but not detail otherwise)
# -> we can use Code.Officiel.Commune...Arrondissement.Municipal

## EPCI
mean(is.element(unique(vaccEPCI$codgeo), as.numeric(geoEPCI$Code.Officiel.Courant.EPCI)))
ii <- which(!is.element(unique(vaccEPCI$codgeo), as.numeric(geoEPCI$Code.Officiel.Courant.EPCI)))
unique(vaccEPCI$codgeo)[ii]
# This is a NA, again one that is not a proper locality, we are fine
# -> we can use Code.Officiel.Courant.EPCI

# Get lat and long for the localities in the datasets
## Communes
tC <- merge(data.frame(codgeo = unique(vacc[, "codgeo"])), geoCom[, c("latitude", "longitude", "Code.Officiel.Commune...Arrondissement.Municipal")], by.x = "codgeo", by.y = "Code.Officiel.Commune...Arrondissement.Municipal")
dim(tC)
length(unique(tC$codgeo))
length(unique(vaccCom$codgeo)) # 3 missing are those where exact location is unknown

## EPCI
tE <- merge(data.frame(codgeo = unique(vacc[, "codgeo"])), geoEPCI[, c("latitude", "longitude", "Code.Officiel.Courant.EPCI")], by.x = "codgeo", by.y = "Code.Officiel.Courant.EPCI")
length(unique(tE$codgeo))
length(unique(vaccEPCI$codgeo)) # 1 missing are those where exact location is unknown

# Join the datasets
dat.GEO <- rbind(tC, tE)
dim(dat.GEO)

# Sanity check
plot(dat.GEO$longitude, dat.GEO$latitude)

#### COMPUTE OTHER GEOGRAPHIC DATA ####

##### Distance Paris #####
iParis <- which(dat.GEO$codgeo == "75104")
lat.Paris <- dat.GEO[iParis, "latitude"]
lon.Paris <- dat.GEO[iParis, "longitude"]

dat.GEO$distanceParis <- sqrt((dat.GEO$latitude - lat.Paris)^2 + (dat.GEO$longitude - lon.Paris)^2)
hist(dat.GEO$distanceParis)

plot(dat.GEO$distanceParis, dat.GEO$latitude)
plot(dat.GEO$distanceParis, dat.GEO$longitude)

##### Diagonals #####
# Standardize lat and long
dat.GEO$lat01 <- (dat.GEO$latitude - min(dat.GEO$latitude)) / (max(dat.GEO$latitude) - min(dat.GEO$latitude))
dat.GEO$lon01 <- (dat.GEO$longitude - min(dat.GEO$longitude)) / (max(dat.GEO$longitude) - min(dat.GEO$longitude))

# Compute diagonals
dat.GEO$SO.NE <- dat.GEO$lat01 + dat.GEO$lon01
dat.GEO$NO.SE <- dat.GEO$lon01 - dat.GEO$lat01

plot(dat.GEO$SO.NE, dat.GEO$lat01)
plot(dat.GEO$NO.SE, dat.GEO$lat01)

#### EXPORT OUTPUT ####
write.csv(dat.GEO, "../data/GEO_brut.csv", row.names = FALSE)
system("git add ../data/GEO_brut.csv")
system("git commit -m 'update GEO dataset'")
