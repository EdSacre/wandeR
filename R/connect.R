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
#' @param kernel The dispersal kernel distribution. Options are 'neg_exp' or
#'     'beta'. Default is 'neg_exp'.
#' @param t Parameter for the negative exponential kernel. Values between 0
#'     and 1 give a normal exponential decay kernel, with values closer to 0
#'     giving a steeper decline. Values above 1 give an essentially linear
#'     distribution. Default value is 0.2.
#' @param a Parameter for the beta distribution kernel. Default value is 3.
#' @param b Parameter for the beta distribution kernel. Default value is 7.
#' @param nthreads Specify the number of threads to use. Default value is 1.
#'
#' @return A spatial raster of connectivity.
#' @export
#' @importFrom foreach "%dopar%"
#' @importFrom utils "globalVariables"

connect <- function(habitats, surface, maxdist, kernel = c("neg_exp", "beta"),
                    t = NULL, a = NULL, b = NULL, nthreads = 1) {

  # Dispersal kernel checks
  kernel <- match.arg(kernel)
  if (kernel == "neg_exp" & !is.null(a) | !is.null(b)) {
    stop("A negative exponential distribution was specified, as well as 'a'
            and 'b' parameters. Did you mean to choose a beta distribution?")
  }
  if (kernel == "beta" & !is.null(t)) {
    stop("A beta distribution was specified, as well as the 't' parameter.
            Did you mean to choose a negative exponential distribution?")
  }

  # Set kernel default values
  if (kernel == "neg_exp") {
    if (is.null(t)) {t <- 0.2}
  }

  if (kernel == "beta") {
    if (is.null(a)) {a <- 3}
    if (is.null(b)) {b <- 7}
  }

  # Raster checks
  surface[surface <= 0] <- NA
  surface[is.nan(surface)] <- NA

  # Store habitat and surface raster parameters
  hvals <- terra::values(habitats) # Store habitat quality values
  hab99 <- habitats # Assign -99 to habitat cells
  hab99[hab99 > 0] <- -99
  ind <- terra::cells(hab99, y = -99)[[1]] # Store indices of habitat cells

  nhab <- terra::ncell(habitats[habitats > 0]) # Store number of habitat cells
  nsurf <- terra::ncell(surface) # Store number of surface cells
  sr <- terra::nrow(surface) # Store number of rows
  sc <- terra::ncol(surface) # Store number of columns
  scrs <- terra::crs(surface) # Store CRS
  sxmin <- terra::xmin(surface) # Store xmin
  sxmax <- terra::xmax(surface) # Store xmax
  symin <- terra::ymin(surface) # Store ymin
  symax <- terra::ymax(surface) # Store ymax
  svals <- terra::values(surface) # Store surface values

  # Define the dispersal kernel
  #h <- 1 / (maxdist * t)

  # Define blocks for parallel processing
  blocks <- seq(from = 0, to = nhab, length.out = nthreads + 1)
  blocks <- round(blocks)

  # Define connectivity helper function to be parallelized
  connect_helper <- function(nhab, nsurf, maxdist, h, ind) {
    base <- c(1:nsurf) * 0
    for (i in 1:nhab) {
      habsurf <- terra::rast(nrows = sr, ncols = sc, crs = scrs, xmin=sxmin, xmax=sxmax, ymin=symin, ymax=symax, vals=svals)
      habsurf[ind[i]] <- -99
      cd <- terra::values(terra::costDist(habsurf, target = -99))
      cd[is.nan(cd)] <- NA
      cd[cd > maxdist] <- NA

      if (kernel == "neg_exp") {
        h <- 1 / (maxdist * t)
        cd[is.na(cd) == FALSE] <- exp(-h * (cd[is.na(cd) == FALSE])) # Negative exponential function
      }
      if (kernel == "beta") {
        cd[is.na(cd) == FALSE] <- dbeta(cd[is.na(cd) == FALSE]/maxdist, a, b) # Beta function
      }

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
      h = h,
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
