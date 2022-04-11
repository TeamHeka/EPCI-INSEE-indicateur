#### PLOT MAP PREDICTOR ####
plotMapVar <- function(varPred, byp = 0.1){
  # varPred: name of the predictor
  # byp: interval for discretization
  # Global variables: datasets, map shapes
  
  # Build minimum dataframe with information on the variable
  tmp <- data.frame(codgeo = dat.all$codgeo, pred = dat.all[, varPred])
  # Discretize the predictor
  tmp$pred.std <- discretizeQ(tmp$pred, prbs = seq(0, 1, by = byp))
  # Add to geographic data
  mergedFrance <- merge(france, tmp, by.x = "SIREN", by.y = "codgeo", all.x = TRUE)
  
  # Main map
  mf_theme("default", mar = c(0, 0, 0, 0), bg = NA)
  
  # Map Parameters
  eBB <- c(.5, .2, 0, 0)
  h2 <- c(0.01, 0.275) # (ymin, ymax) of the metropoles
  
  # Color palette
  nn <- 1/byp # number of types
  palCat <- rev(met.brewer("Hiroshige", nn, type = "continuous"))
  names(palCat) <- 1:nn
  
  brks <- quantile(tmp$pred, probs = seq(0, 1, by = byp), na.rm = TRUE)
  
  # Initialize map
  mf_init(france, expandBB = eBB)
  
  # Rename variable
  tit <- varPred
  if(substr(tit, 1, 1) == "X") tit <- substr(tit, 2, nchar(tit))
  
  # Plot map
  mf_map(mergedFrance, type = "choro", var = "pred", 
         pal = palCat, breaks = brks,
         border = gray(0, 0), add = TRUE, 
         leg_pos = "topleft", leg_title = paste0(tit, ", discretized"), leg_no_data = "no data", leg_val_cex = 0.5, leg_val_rnd = 3)
  
  # Fill in PLM
  plm <- france[is.element(france$SIREN, epci.PLM), ]
  mf_map(plm, add = TRUE, border = gray(0, 0), col = gray(0.7))
  
  
  # Add departements
  mf_map(mdeps, type = "base", add = TRUE, col = gray(0, 0), lwd = 0.5, border = "black")
  # Add regions
  mf_map(mregions.metro, type = "base", add = TRUE, col = gray(0, 0), border = "black", lwd = 0.8)
  
  # Add cities
  chfl.dep$pt <- 1
  chfl.reg$pt <- 1
  mf_map(x = chfl.dep, type = "prop", var = "pt", inches = 0.015, col = gray(1), leg_pos = "n")
  mf_map(x = chfl.reg, type = "prop", var = "pt", inches = 0.03, col = gray(1), leg_pos = "n")
  
  mf_label(x = chfl.reg, var = "nom", halo = TRUE, bg = gray(1, 0.5), adj = c(0.5, -1), r = 0.1, cex = 0.6, overlap = FALSE)
  
  
  #.....................................................
  
  # Metropoles
  marMet <- c(0, 0, .8, 0) # margin
  
  # PARIS
  mf_inset_on(fig = c(0, 0.33, h2))
  mf_theme(mar = marMet)
  paris <- tca[is.element(substr(tca$insee, 1,2), c("75", "91", "92", "93", "94", "95")), ]
  paris <- merge(paris, tmp, by.x = "insee", by.y = "codgeo", all.x = TRUE)
  
  mf_map(paris, 
         type = "choro", breaks = brks, var = "pred", pal = palCat, 
         leg_pos = "n")
  mf_title(txt = "Métropole du Grand Paris", pos = "center", tab = FALSE, bg = NA, 
           fg = "black", cex = .65, line = .8)
  mf_inset_off()
  
  # LYON
  mf_inset_on(fig = c(0.33, 0.66, h2))
  mf_theme(mar = marMet)
  
  lyon <- tca[is.element(substr(tca$insee, 1,2), c("69")),]
  lyon <- merge(lyon, tmp, by.x = "insee", by.y = "codgeo", all.x = TRUE)
  mf_map(lyon, 
         type = "choro", breaks = brks, var = "pred", pal = palCat, 
         leg_pos = "n")
  mf_title(txt = "Métropole de Lyon", pos = "center", tab = FALSE, bg = NA, 
           fg = "black", cex = .7, line = .8)
  mf_inset_off()
  
  mf_inset_on(fig = c(.66, 1, h2))
  mf_theme(mar = marMet)
  
  # MARSEILLE
  marseille <- merge(tca[is.element(substr(tca$insee, 1,2), c("13", "83", "84")), ], tmp, by.x = "insee", by.y = "codgeo", all.x = TRUE)
  
  mf_map(marseille, 
         type = "choro", breaks = brks, var = "pred", pal = palCat, 
         leg_pos = "n")
  mf_title(txt = "Métropole d'Aix-Marseille-Provence", pos = "center", tab = FALSE, bg = NA, 
           fg = "black", cex = .7, line = .8)
  mf_inset_off()
}


#............................................................................................................

#### PLOT MAP VACCINATION #####

plotMapVacc <- function(tabVacc, byp = 2.5, zmin = NA, zmax = NA, thetitle = "Adult vaccination rates", palName = "Cassatt2"){
  # tabVacc: table of vaccination rates by codgeo
    # byp: interval for discretization
  # Global variables: datasets, map shapes
  
  layout(matrix(c(1, 1, 1, 2, 3, 4), byrow = TRUE, ncol = 3), heights = c(3, 1))
  
  tabVacc$pourcentVacc <- tabVacc$taux_cumu * 100
  
  # Add to geographic data
  mergedFrance <- merge(france, tabVacc, by.x = "SIREN", by.y = "codgeo", all.x = TRUE)
  
  # Main map
  mf_theme("default", mar = c(0, 0, 0, 0), bg = NA)
  
  if(is.na(zmin)){
    zmin <- 5 * floor(min(tabVacc$pourcentVacc, na.rm = TRUE)/5)
  }
  if(is.na(zmax)){
    zmax <- 5 * ceiling(max(tabVacc$pourcentVacc, na.rm = TRUE)/5)
  }
  
  # Map Parameters
#  eBB <- c(.5, .2, 0, 0)
  eBB <- c(0, 0.2, 0, 0)
  h2 <- c(0.01, 0.275) # (ymin, ymax) of the metropoles
  
  # Color palette
  #names(palCat) <- 1:nn
  
  
  brks <- seq(zmin, zmax, by = byp)
  nn <- length(brks) # number of types
  if(palName == "Cassatt2"){
    palCat <- met.brewer(palName, nn, type = "continuous")
  }else{
    palCat <- rev(met.brewer(palName, nn, type = "continuous"))
  }
  
  ii <- which(brks >= 0 & brks <= 100)
  brks <- brks[ii]
  palCat <- palCat[ii]  
  
  # Initialize map
  mf_init(france, expandBB = eBB)
  
  # Rename
  tit <- thetitle

  # Plot map
  mf_map(mergedFrance, type = "choro", var = "pourcentVacc", 
         pal = palCat, breaks = brks,
         border = gray(0, 0), add = TRUE, 
         leg_pos = "topleft", leg_title = paste0(thetitle), leg_no_data = "no data", leg_val_cex = 0.5, leg_val_rnd = 3)
  
  # Fill in PLM
  plm <- france[is.element(france$SIREN, epci.PLM), ]
  mf_map(plm, add = TRUE, border = gray(0, 0), col = gray(0.7))
  
  
  # Add departements
  mf_map(mdeps, type = "base", add = TRUE, col = gray(0, 0), lwd = 0.5, border = "black")
  # Add regions
  mf_map(mregions.metro, type = "base", add = TRUE, col = gray(0, 0), border = "black", lwd = 0.8)
  
  # Add cities
  chfl.dep$pt <- 1
  chfl.reg$pt <- 1
  mf_map(x = chfl.dep, type = "prop", var = "pt", inches = 0.015, col = gray(1), leg_pos = "n")
  mf_map(x = chfl.reg, type = "prop", var = "pt", inches = 0.03, col = gray(1), leg_pos = "n")
  
  mf_label(x = chfl.reg, var = "nom", halo = TRUE, bg = gray(1, 0.5), adj = c(0.5, -1), r = 0.1, cex = 0.6, overlap = FALSE)
  
  
  #.....................................................
  
  # Metropoles
  marMet <- c(0, 0, .8, 0) # margin
  
  # PARIS
#  mf_inset_on(fig = c(0, 0.33, h2))
  mf_theme(mar = marMet)
  paris <- tca[is.element(substr(tca$insee, 1,2), c("75", "91", "92", "93", "94", "95")), ]
  paris <- merge(paris, tabVacc, by.x = "insee", by.y = "codgeo", all.x = TRUE)
  
  mf_map(paris, 
         type = "choro", breaks = brks, var = "pourcentVacc", pal = palCat, 
         leg_pos = "n")
  mf_title(txt = "Métropole du Grand Paris", pos = "center", tab = FALSE, bg = NA, 
           fg = "black", cex = .65, line = .8)
#  mf_inset_off()
  
  # LYON
#  mf_inset_on(fig = c(0.33, 0.66, h2))
  mf_theme(mar = marMet)
  
  lyon <- tca[is.element(substr(tca$insee, 1,2), c("69")),]
  lyon <- merge(lyon, tabVacc, by.x = "insee", by.y = "codgeo", all.x = TRUE)
  mf_map(lyon, 
         type = "choro", breaks = brks, var = "pourcentVacc", pal = palCat, 
         leg_pos = "n")
  mf_title(txt = "Métropole de Lyon", pos = "center", tab = FALSE, bg = NA, 
           fg = "black", cex = .7, line = .8)
#  mf_inset_off()
  
#  mf_inset_on(fig = c(.66, 1, h2))
  mf_theme(mar = marMet)
  
  # MARSEILLE
  marseille <- merge(tca[is.element(substr(tca$insee, 1,2), c("13", "83", "84")), ], tabVacc, by.x = "insee", by.y = "codgeo", all.x = TRUE)
  
  mf_map(marseille, 
         type = "choro", breaks = brks, var = "pourcentVacc", pal = palCat, 
         leg_pos = "n")
  mf_title(txt = "Métropole d'Aix-Marseille-Provence", pos = "center", tab = FALSE, bg = NA, 
           fg = "black", cex = .7, line = .8)
#  mf_inset_off()
}
