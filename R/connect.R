#' @title connect
#'
#' @description Generates a connectivity raster based on species habitat locations.
#'     The connectivity model determines connectivity based on a dispersal kernel,
#'     obstacles to movement (e.g. land), and habitat quality.
#'
#' @param habitats A raster of species habitats or known locations.
#' @param destinations A raster of the land or seascape. Values of 0 or NA are considered "barriers".
#'     Values greater than 0 are considered valid locations to travel through.
#' @param ncores The number of cores to use when running the model.
#'
#' @return A spatial raster of connectivity.
#' @export
#' @importFrom gdistance "costDistance"
#' @importFrom gdistance "transition"

connect <- function() {
  print("Hello, world!")
}
