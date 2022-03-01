# Function to recompute vaccination rates

# Adjusting the age distribution of each locality as if it were the same as that of the whole country

adjustVacc <- function(r1, varVacc = "1_inj"){
  # r1  vaccination dataset for a given date, with all ages, but not "TOUT_AGE"
  # varVacc  the vaccination variable that we want to investigate ("1_inj" or "termine")
  
  # Compute distribution of the population by age class
  #   Population size of each age classs
  distPop <- aggregate(r1$population_carto, by = list(classe_age = r1$classe_age), FUN = sum, na.rm = TRUE)
  #   Proportions
  distPop$propAgeClass <- distPop$x / sum(distPop$x)
  
  # Merge with vaccination data
  rr1 <- merge(r1, distPop, by = "classe_age")
  
  # Compute adjusted rates, by weighting each by each by the proportion in the overall population
  s1 <- aggregate(data.frame(taux_cumu = rr1[, paste0("taux_cumu_", varVacc)] * rr1$propAgeClass, population_carto = rr1$population_carto), by = list(codgeo = rr1$codgeo), FUN = sum, na.rm = TRUE)
  # Compute adjusted numbers of vaccinated people
  s1$n_cumu <- round(s1$taux_cumu * s1$population_carto)
  
  # Return the dataframe
  s1
}

#.........................................................................................

#  Removing children (00-19 age class)

adultVacc <- function(r1, varVacc = "1_inj"){
  # r1  vaccination dataset for a given date, with all ages, but not "TOUT_AGE"
  # varVacc  the vaccination variable that we want to investigate ("1_inj" or "termine")
  
  # Remove children age class
  rr1 <- r1[which(r1$classe_age != "00-19"), ]
  
  # Compute sums of effectifs by codgeo
  s1 <- aggregate(data.frame(n_cumu = rr1[, paste0("effectif_cumu_", varVacc)], population_carto = rr1$population_carto), by = list(codgeo = rr1$codgeo), FUN = sum, na.rm = TRUE)
  
  # Compute taux
  s1$taux_cumu <- s1$n_cumu / s1$population_carto
  
  # Return the dataframe
  s1
}
