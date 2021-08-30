# INITIALIZATIONS ####

# Load packages
# install.packages("mapsf")
library(mapsf)

library(RColorBrewer)

library(colorspace)

# Load data #####

## France and DOM

# Source <https://www.banatic.interieur.gouv.fr/V5/cartographie/cartographie.php>
  
france <- st_read("../data/geographic/contours_epci/2021/Metropole/EPCI_2021_region.shp")

guadeloupe <- st_read("../data/geographic/contours_epci/2021/Guadeloupe/contours_epci_971_region.shp")
guyane <- st_read("../data/geographic/contours_epci/2021/Guyane/contours_epci_973_region.shp")
guyane <- st_read("../data/geographic/contours_epci/2021/Guyane/contours_epci_973_region.shp")
reunion <- st_read("../data/geographic/contours_epci/2021/LaReunion/contours_epci_974_region.shp")
martinique <- st_read("../data/geographic/contours_epci/2021/Martinique/contours_epci_972_region.shp")
mayotte <- st_read("../data/geographic/contours_epci/2021/Mayotte/Contour_epci_976_region.shp")

names(france)

## Other data 

# Pour les infos sur les départements
# Source <https://www.insee.fr/fr/information/2510634>
composition <- read.csv("../data/geographic/EPCI_composition-communale.csv", encoding = "UFT-8")

# Departement information

departements <- read.csv("../data/geographic/departement2020.csv")

dic.depname <- departements$libelle
names(dic.depname) <- departements$dep


# Information about departement in which the different EPCI are
# Some are across multiple departements: keep the information by collating them with "_"
agg_nbdep <- aggregate(composition$DEP, by = list(EPCI = composition$EPCI), FUN = function(i) paste(sort(unique(i)), collapse = "_"))
table(agg_nbdep$x)

# Dictionnary of departement(s) associated to EPCI
dic.dep <- agg_nbdep$x
names(dic.dep) <- agg_nbdep$EPCI

# Not listed
notlisted <- !is.element(france$SIREN, agg_nbdep$EPCI)
sum(notlisted)

# Add the dep information to our data
france$dep <- dic.dep[as.character(france$SIREN)]

france$outremer <- (nchar(france$dep) == 3)
france$dep1 <- substr(france$dep, 1, 2)
france[which(france$outremer), "dep1"] <- france[which(france$outremer), "dep"]

## Communes

### All communes and arrondissements
  
# Source tout <https://www.data.gouv.fr/en/datasets/decoupage-administratif-communal-francais-issu-d-openstreetmap/>
  
#  Licence © les contributeurs d'OpenStreetMap sous licence ODbL
# Toutes les communes
toutescommunes <- st_read("../data/geographic/communes-20210101-shp/communes-20210101.shp")

names(toutescommunes)
toutescommunes[1,]

# Arrondissements Paris Lyon Marseille

arrondissements <- st_read("../data/geographic/arrondissements_municipaux-20180711-shp/arrondissements_municipaux-20180711.shp")
names(arrondissements)


