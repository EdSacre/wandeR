#' @title connect.helper
#'
#' @description Generates a connectivity raster based on species habitat locations.
#'     The connectivity model determines connectivity based on a dispersal kernel,
#'     obstacles to movement (e.g. land), and habitat quality.
#'
#' @param nhab Number of habitat cells
#' @param ndest Number of destination cells
#' @param trans Transition raster
#' @param hpoint Habitat points
#' @param dpoint Destination points
#' @param maxdist Maximum kernel distance
#' @param a Parameter -a- for dispersal kernel
#'
#' @return A spatial raster of connectivity.
#' @importFrom gdistance "costDistance"
#' @importFrom gdistance "transition"

connect.helper <- function(nhab, ndest, trans, hpoint, dpoint, maxdist, a) {
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
  return(base)
}
