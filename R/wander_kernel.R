#' @title wander_kernel
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
#' @return A vector of dispersal probabilities
#' @export

#wander_kernel <- function(maxdist = 10000, ){
#
#}
