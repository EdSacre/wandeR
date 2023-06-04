#' @title wander_data
#'
#' @description Fetch example data for the wandeR package
#'
#' @param name Name of the dataset to be fetched. Options are: "coral" and "zanzibar".
#'
#' @return A raster.
#' @export
#' @importFrom raster "raster"

wander_data <- function(name){
  raster(system.file("extdata", paste0(name, ".tif"), package = "wandeR"))
}
