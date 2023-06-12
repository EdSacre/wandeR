#' @title highway
#'
#' @description Generates a connectivity raster based on species habitat locations.
#'     The connectivity model determines connectivity based on least cost paths, and
#'     obstacles to movement (e.g. land)
#'
#' @param habitats A raster of species habitats or known locations.
#' @param surface A raster of the land or seascape. Values of 0 or NA are considered "barriers".
#'     Values greater than 0 are considered valid locations to travel through.
#' @param maxdist The maximum dispersal distance of the species in map units.
#' @param nthreads Specify the number of threads to use.
#'
#' @return A spatial raster of connectivity.
#' @export
#' @importFrom foreach "%dopar%"
#' @importFrom utils "globalVariables"

highway <- function(habitats, surface, maxdist, nthreads = 1){

  # Define the helper function to be parallelized
  highway_helper <- function(i, hpoint, maxdist, trans, surface, path_buffer){
    cd <- gdistance::costDistance(trans, hpoint[i,], hpoint)
    cd <- cd[1,]
    habt <- which(cd < maxdist)
    habt <- habt[habt != i]

    base <- surface*0
    base[is.na(base)] <- 0

    for(j in habt){
      s <- gdistance::shortestPath(x = trans, origin = hpoint[i,], goal = hpoint[j,], output = "SpatialLines") |>
        terra::vect(type="lines") |>
        terra::rasterize(y = terra::rast(surface), field = 1) |>
        terra::as.points() |>
        as("Spatial")
      s <- gdistance::accCost(trans, s)
      s[s > path_buffer] <- NA
      s <- path_buffer - s
      s[is.na(s)] <- 0
      base <- s + base
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

  # Define the buffer around leas cost paths
  path_buffer <- maxdist/20

  # Create the transition layer from "gdistance" package and convert rasters to point
  trans <- gdistance::transition(surface, transitionFunction = min, directions = 8) # Transition file
  trans <- gdistance::geoCorrection(trans, type = "c") # Geo-correct transition file
  hpoint <- raster::rasterToPoints(habitats, spatial = TRUE) # Set the origin points
  dpoint <- raster::rasterToPoints(surface, spatial = TRUE) # Set the destination points

  fbase <- foreach(i = 1:length(hpoint), .combine = "+", .packages = c("gdistance", "terra", "raster")) %dopar% {
    highway_helper(i, hpoint, maxdist, trans, surface, path_buffer)
  }
  parallel::stopCluster(cl = clust) # Stop cluster

  fbase[is.na(surface)] <- NA
  return(fbase)

}
