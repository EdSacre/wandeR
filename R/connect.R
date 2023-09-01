#' @title connect
#'
#' @description Generates a connectivity raster based on species habitat locations.
#'     The connectivity model determines connectivity based on a dispersal kernel,
#'     obstacles to movement (e.g. land), and habitat quality.
#'
#' @param habitats A raster of species habitats or known locations.
#' @param surface A raster of the land or seascape. Values of 0 or NA are considered "barriers".
#'     Values greater than 0 are considered valid locations to travel through.
#' @param maxdist The maximum dispersal distance of the species in map units.
#' @param t Parameter for the negative exponential kernel. Values between 0 and 1 give a normal exponential decay kernel,
#'     with values closer to 0 giving a steeper decline. Values above 1 give an essentially linear distribution. Default value is 0.2.
#' @param nthreads Specify the number of threads to use. Default value is 1.
#'
#' @return A spatial raster of connectivity.
#' @export
#' @importFrom foreach "%dopar%"
#' @importFrom utils "globalVariables"

connect <- function(habitats, surface, maxdist, t = 0.2, nthreads = 1) {

  # Define connectivity function to be parallelized
  connect_helper <- function(nhab, ndest, trans, hpoint, dpoint, maxdist, a) {
    base <- c(1:ndest) * 0
    for(i in 1:nhab){
      cd <- gdistance::costDistance(trans, hpoint[i,], dpoint)
      cd <- cd[1,]
      cd[cd > maxdist] <- NA
      cd[is.na(cd) == FALSE] <- exp(-a*(cd[is.na(cd) == FALSE]))
      cd[is.na(cd) == TRUE] <- 0
      #cd <- cd * speco[i,]$habvalue # Add this line to give higher connectivity values to higher habitat quality/coverage
      cd <- cd * hpoint@data[[1]][i] # Add this line to give higher connectivity values to higher habitat quality/coverage
      base <- base+cd
    }
    return(base)
  }

  # Enable parallel processing
  clust <- parallel::makeCluster(nthreads, type = "PSOCK")
  doParallel::registerDoParallel(cl = clust)
  foreach::getDoParRegistered()

  # Checks
  habitats[habitats == 0] <- NA
  surface[surface == 0] <- NA

  # Define the dispersal kernel
  a <- 1/(maxdist * t)

  # Create the transition layer from "gdistance" package and convert rasters to point
  trans <- gdistance::transition(surface, transitionFunction = min, directions = 8) # Transition file
  trans <- gdistance::geoCorrection(trans, type = "c") # Geo-correct transition file
  hpoint <- raster::rasterToPoints(habitats, spatial = TRUE) # Set the origin points
  dpoint <- raster::rasterToPoints(surface, spatial = TRUE) # Set the destination points

  nhab <- length(hpoint)
  ndest <- length(dpoint)

  blocks <- seq(from = 0, to = nhab, length.out = nthreads+1)
  blocks <- round(blocks)

  pfcd <- foreach::foreach(i=1:nthreads, .combine = '+', .packages=c("foreach")) %dopar% {
    k <- (blocks[i]+1):blocks[i+1]
    connect_helper(nhab = length(k),
                    ndest = ndest,
                    hpoint = hpoint[k,],
                    dpoint = dpoint,
                    trans = trans,
                    maxdist = maxdist,
                    a = a)
  }

  parallel::stopCluster(cl = clust) # Stop cluster

  # Send outputs to raster
  ras <- surface
  ras[is.na(ras) == F] <- pfcd
  return(ras)
}

if(getRversion() >= "2.15.1")  utils::globalVariables("i")
