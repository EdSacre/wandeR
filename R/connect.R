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
#' @param nthreads Specify the number of threads to use.
#'
#' @return A spatial raster of connectivity.
#' @export
#' @importFrom foreach "%dopar%"
#' @importFrom utils "globalVariables"

connect <- function(habitats, destinations, maxdist, nthreads = 1) {
  # Enable parallel processing
  clust <- parallel::makeCluster(nthreads, type = "PSOCK")
  doParallel::registerDoParallel(cl = clust)
  foreach::getDoParRegistered()

  # Checks
  habitats[habitats == 0] <- NA
  destinations[destinations == 0] <- NA

  # Define the dispersal kernel
  d <- maxdist * 0.3 # This defines how steep the dispersal kernel is - a value of 1 is almost linear
  a <- 1/d # this specifies that the dispersal kernel should taper towards 0 around the max dist

  # Create the transition layer from "gdistance" package and convert rasters to point
  trans <- gdistance::transition(destinations, transitionFunction = min, directions = 8) # Transition file
  trans <- gdistance::geoCorrection(trans, type = "c") # Geo-correct transition file
  hpoint <- raster::rasterToPoints(habitats, spatial = TRUE) # Set the origin points
  dpoint <- raster::rasterToPoints(destinations, spatial = TRUE) # Set the destination points

  nhab <- length(hpoint)
  ndest <- length(dpoint)

  blocks <- seq(from = 0, to = nhab, length.out = nthreads+1)
  blocks <- round(blocks)

  pfcd <- foreach::foreach(p=1:nthreads, .combine = '+', .packages="foreach") %dopar% {
    k <- (blocks[p]+1):blocks[p+1]
    connect.helper(nhab = length(k),
                    ndest = ndest,
                    hpoint = hpoint[k,],
                    dpoint = dpoint,
                    trans = trans,
                    maxdist = maxdist,
                    a = a)
  }

  parallel::stopCluster(cl = clust) # Stop cluster

  # Send outputs to raster
  ras <- destinations
  ras[is.na(ras) == F] <- pfcd
  return(ras)
}

if(getRversion() >= "2.15.1")  utils::globalVariables("p")
