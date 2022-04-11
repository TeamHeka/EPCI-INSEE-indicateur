# Update datasets #


# Load vaccination data

# Source: https://datavaccin-covid.ameli.fr/explore/?exclude.theme=Datavisualisation&sort=modified

URL.AmeliCom <- "https://datavaccin-covid.ameli.fr/explore/dataset/donnees-de-vaccination-par-commune/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=%3B"

system(paste0("wget -O ../data/ameli_vaccination/vaccCom.csv ", URL.AmeliCom))


URL.AmeliEPCI <- "https://datavaccin-covid.ameli.fr/explore/dataset/donnees-de-vaccination-par-epci/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=%3B"

system(paste0("wget -O ../data/ameli_vaccination/vaccEPCI.csv ", URL.AmeliEPCI))


