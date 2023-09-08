#' @title connect
#'
#' @description Generates a connectivity raster based on species habitat
#'     locations. The connectivity model determines connectivity based on a
#'     dispersal kernel, obstacles to movement (e.g. land), and habitat quality.
#'
#' @param habitats A raster(RasterLayer) of species habitats or known locations.
#' @param surface A raster(RasterLayer) of the land or seascape. Values of 0 or
#'     NA are considered "barriers". Values greater than 0 are considered valid
#'     locations to travel through.
#' @param maxdist The maximum dispersal distance of the species in map units.
#' @param t Parameter for the negative exponential kernel. Values between 0 and
#'     1 give a normal exponential decay kernel, with values closer to 0 giving
#'     a steeper decline. Values above 1 give an essentially linear
#'     distribution. Default value is 0.2.
#' @param nthreads Specify the number of threads to use. Default value is 1.
#'
#' @return A spatial raster of connectivity.
#' @export
#' @importFrom foreach "%dopar%"
#' @importFrom utils "globalVariables"

connect <- function(habitats, surface, maxdist, t = 0.2, nthreads = 1) {

  # Raster checks
  surface[surface <= 0] <- NA
  surface[is.nan(surface)] <- NA

  # Store habitat and surface raster parameters
  hvals <- terra::values(habitats) # Store habitat quality values
  hab99 <- habitats # Assign -99 to habitat cells
  hab99[hab99 > 0] <- -99
  ind <- terra::cells(hab99, y = -99)[[1]] # Store indices of habitat cells

  nhab <- ncell(habitats[habitats > 0]) # Store number of habitat cells
  nsurf <- ncell(surface) # Store number of surface cells
  sr <- terra::nrow(surface) # Store number of rows
  sc <- terra::ncol(surface) # Store number of columns
  scrs <- terra::crs(surface) # Store CRS
  sxmin <- terra::xmin(surface) # Store xmin
  sxmax <- terra::xmax(surface) # Store xmax
  symin <- terra::ymin(surface) # Store ymin
  symax <- terra::ymax(surface) # Store ymax
  svals <- terra::values(surface) # Store surface values

  # Define the dispersal kernel
  a <- 1 / (maxdist * t)

  # Define blocks for parallel processing
  blocks <- seq(from = 0, to = nhab, length.out = nthreads + 1)
  blocks <- round(blocks)

  # Define connectivity helper function to be parallelized
  connect_helper <- function(nhab, nsurf, maxdist, a, ind) {
    base <- c(1:nsurf) * 0
    for (i in 1:nhab) {
      habsurf <- terra::rast(nrows = sr, ncols = sc, crs = scrs, xmin=sxmin, xmax=sxmax, ymin=symin, ymax=symax, vals=svals)
      habsurf[ind[i]] <- -99
      cd <- terra::values(terra::costDist(habsurf, target = -99))
      cd[is.nan(cd)] <- NA
      cd[cd > maxdist] <- NA
      cd[is.na(cd) == FALSE] <- exp(-a * (cd[is.na(cd) == FALSE]))
      cd[is.na(cd) == TRUE] <- 0
      cd <- cd * hvals[ind[i]] # Give higher connectivity values to higher habitat quality/coverage
      base <- base + cd
    }
    return(base)
  }

  # Enable parallel processing
  clust <- parallel::makeCluster(nthreads, type = "PSOCK")
  doParallel::registerDoParallel(cl = clust)
  foreach::getDoParRegistered()

  # Perform connect function in parallel
  pfcd <- foreach::foreach(i = 1:nthreads, .combine = "+", .packages = c("foreach")) %dopar% {
    k <- (blocks[i] + 1):blocks[i + 1]
    connect_helper(
      nhab = length(k),
      nsurf = nsurf,
      maxdist = maxdist,
      a = a,
      ind = ind[k]
    )
  }

  parallel::stopCluster(cl = clust) # Stop cluster

  # Send outputs to raster
  ras <- surface
  pfcd[is.na(svals)] <- NA
  ras[] <- pfcd
  return(ras)
}

if (getRversion() >= "2.15.1") utils::globalVariables("i")
