dat.GEO <- read.csv("../data/GEO_brut_OLD.csv")

# Some values were erroneously entered, this script corrects them
ierrors <- which(as.numeric(substr(dat.GEO$latitude, 1, 2)) < 35)

# Correct the errors for Marseille
dat.GEO[ierrors, "latitude"] <- dat.GEO[ierrors, "latitude"] + 30

dat.GEO$lat01 <- (dat.GEO$latitude - min(dat.GEO$latitude)) / (max(dat.GEO$latitude) - min(dat.GEO$latitude))
hist(dat.GEO$lat01)
hist(dat.GEO$lon01)

# Recompute distance to Paris
# Paris = Paris 04
iParis <- which(dat.GEO$codgeo == "75104")
lat.Paris <- dat.GEO[iParis, "latitude"]
lon.Paris <- dat.GEO[iParis, "longitude"]

dat.GEO$distanceParis <- sqrt((dat.GEO$latitude - lat.Paris)^2 + (dat.GEO$longitude - lon.Paris)^2)
hist(dat.GEO$distanceParis)

plot(dat.GEO$longitude, dat.GEO$latitude)
plot(dat.GEO$SO.NE, dat.GEO$latitude - dat.GEO$longitude)

# Remove the erroneous verions
dat.GEO <- dat.GEO[, which(names(dat.GEO) != "distParis")]

# Export the corrected dataset
write.csv(x = dat.GEO, file = "../data/GEO_brut.csv", row.names = FALSE)

