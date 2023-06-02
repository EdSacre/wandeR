#' @title connect
#'
#' @description Generates a connectivity raster based on species habitat locations.
#'     The connectivity model determines connectivity based on a dispersal kernel,
#'     obstacles to movement (e.g. land), and habitat quality.
#'
#' @param habitats A raster of species habitats or known locations.
#' @param destinations A raster of the land or seascape. Values of 0 or NA are considered "barriers".
#'     Values greater than 0 are considered valid locations to travel through.
#' @param maxdist The maximum dispersal distance of the species in map units.
#'
#' @return A spatial raster of connectivity.
#' @export
#' @importFrom gdistance "costDistance"
#' @importFrom gdistance "transition"

connect <- function(habitats, destinations, maxdist) {
  # Checks
  habitats[habitats == 0] <- NA

  d <- maxdist * 0.3 # This defines how steep the dispersal kernel is - a value of 1 is almost linear
  a <- 1/d # this specifies that the dispersal kernel should taper towards 0 around the max dist

  nhab <- length(habitats[habitats > 0])
  ndest <- length(destinations[is.na(destinations) == FALSE])

  trans <- gdistance::transition(destinations, transitionFunction = min, directions = 8) # Transition file
  trans <- gdistance::geoCorrection(trans, type = "c") # Geo-correct transition file
  hpoint <- raster::rasterToPoints(habitats, spatial = TRUE) # Set the origin points
  dpoint <- raster::rasterToPoints(destinations, spatial = TRUE) # Set the destination points
  base <- c(1:ndest) * 0

  for(i in 1:nhab){
    cd <- gdistance::costDistance(trans, hpoint[i,], dpoint)
    cd <- cd[1,]
    cd[cd > maxdist] <- NA
    cd[is.na(cd) == FALSE] <- exp(-a*(cd[is.na(cd) == FALSE]))
    cd[is.na(cd) == TRUE] <- 0
    #cd <- cd * speco[i,]$habvalue # Add this line to give higher connectivity values to higher habitat quality/coverage
    base <- base+cd
  }

  outcon <- destinations * 0
  outcon[is.na(outcon) == F] <- base
  return(outcon)
}
