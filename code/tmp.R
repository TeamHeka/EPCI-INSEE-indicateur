library(mapsf) # Package to plot maps
library(rmapshaper) # Package to simplify the maps

load("../data/geographic/mapFiles.RData")

keepRatio <- 0.005 # proportion of points to retain (0-1; default 0.05)
keepShapes <- FALSE # Prevent small polygon features from disappearing at high simplification (default FALSE)

map.departements <- read_sf("../data/maps/departements-20180101-shp/departements-20180101.shp")

map.regions <- read_sf("../data/maps/regions-20180101-shp/regions-20180101.shp")

dep2017 <- read_sf("../data/maps/departements-20170102-shp/departements-20170102.shp")

# Simplify shapes ####
# And replace the files
mdeps <- ms_simplify(map.departements, keep = keepRatio, keep_shapes = keepShapes)
mregions <- ms_simplify(map.regions, keep = keepRatio, keep_shapes = keepShapes)
#mdeps17 <- ms_simplify(dep2017, keep = keepRatio, keep_shapes = keepShapes)

mdeps.metro <- mdeps[!(nchar(mdeps$code_insee) == 3 & substr(mdeps$code_insee, 1, 1) == 9) ,]
mregions.metro <- mregions[as.numeric(mregions$code_insee) > 09, ]

#mdeps17.metro <- mdeps17[!(nchar(mdeps17$code_insee) == 3 & substr(mdeps17$code_insee, 1, 1) == 9) ,]

head(mregions)

france2 <- st_transform(france, crs = "WGS84")


head(france2)

outerFrance2 <- st_union(france2)
outerRegions <- st_union(mregions.metro)

mf_map(mdeps17.metro)
mf_init(france)
mf_map(france)
mf_map(mregions.metro, col = "red")
mf_map(mdeps, col = gray(0,0.1), add = TRUE)
mf_map(france2, col = gray(0,0.1), add = TRUE)

mf_map(mdeps, type = "base")
head(france2)

mf_map(france2, type = "choro", var = "POPULATION", border = gray(0.9, 0.1))
mf_map(mdeps, type = "base", add = TRUE, col = gray(0, 0), lwd = 0.5, border = "white")
mf_map(mregions.metro, type = "base", add = TRUE, col = gray(0, 0), border = "black", lwd = 0.6)

mf_map(outerRegions, add = TRUE, col = gray(0, 0), lwd = 1)




mf_map(mdeps.metro, type = "base")
mf_map(tca, add = TRUE)

head(france)
head(tca)
head(mdeps)

dim(france)
?st_union

dep69 <- mdeps[substr(mdeps$code_insee, 1, 2) == "69", ]
dep69
mf_map(dep69)

mf_map(st_union(dep69))

tmp <- mdeps.metro[!(substr(mdeps.metro$code_insee, 1, 2) == "69"), ]
tmp[1, "geometry"]

mdeps.metro[mdeps.metro$nom == "Rhône", "geometry"] <- tmp[1, "geometry"]
mdeps.metro[mdeps.metro$nom == "Rhône", ]

mdeps.metro2 <- rbind(tmp, st_union(dep69))

head(tmp)
head(st_union(dep69))

rbind(tmp, st_union(dep69))


mf_map(mdeps.metro)
mf_map(tmp)


head(mdeps)
d69 <- st_union(mdeps, by_feature = substr(mdeps$code_insee, 1, 2) == "69")
mf_map(d69)

head(mdeps.metro)
mf_map(map.departements.metro, type = "base")

mdeps[mdeps$code_insee == "69M",]

mdeps$code_insee < "99"
head(mdeps)
head(france)


map.deps <- read.csv("../data/maps/formes-geographiques-des-departements-en-svg.csv", sep = ";")
head(map.deps)
names(map.deps)


mf_init(x = france)
mf_map(france, add = TRUE, 
       leg_pos = "topleft", leg_title = "BLABLA")

map.departements <- read_sf("../data/maps/departements-20180101-shp/departements-20180101.shp")

mf_init(map.departements)
mf_map(map.departements, add = TRUE)

str(map.deps)

library("sf")

m.epci <- st_read("../data/maps/georef-france-epci/georef-france-epci-millesime.shp")
?st_as_sf

head(m.epci)
mf_init(x = m.epci)
mf_map(m.epci, add = TRUE, 
       leg_pos = "topleft", leg_title = "BLABLA")

library("mapsf")
getwd()

?st_read
france <- st_read("../../ data/contours_epci/2021/Metropole/EPCI_2021_region.shp")

st_as_sf(map.deps)
