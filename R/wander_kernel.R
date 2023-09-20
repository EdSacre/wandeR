#' @title wander_kernel
#'
#' @description Generates plots of different dispersal kernels that
#'     can be implemented in the 'connect' function. There are two dispersal+
#'     kernel options, a negative exponential (default) or a beta distribution.
#'     Test different parameter values to inform what values are chosen for the
#'     connectivity modelling.
#'
#' @param maxdist The maximum dispersal distance of the species. Default is
#'     10,000.
#' @param kernel The dispersal kernel distribution. Options are 'neg_exp' or
#'     'beta'. Default is 'neg_exp'.
#' @param t Parameter for the negative exponential kernel. Values between 0
#'     and 1 give a normal exponential decay kernel, with values closer to 0
#'     giving a steeper decline. Values above 1 give an essentially linear
#'     distribution. Default value is 0.2.
#' @param a Parameter for the beta distribution kernel. Default value is 3.
#' @param b Parameter for the beta distribution kernel. Default value is 7.
#'
#' @return A plot of specified dispersal kernels.
#' @export
#' @importFrom graphics "mtext"
#' @importFrom stats "dbeta"

wander_kernel <- function(maxdist = 10000, kernel = c("neg_exp", "beta"), t = NULL, a = NULL, b = NULL) {
  kernel <- match.arg(kernel)

  # Throw warnings if chosen distributions do not match chosen parameters
  if (kernel == "neg_exp" & (!is.null(a) | !is.null(b))) {
    stop("A negative exponential distribution was specified, as well as 'a'
            and 'b' parameters. Did you mean to choose a beta distribution?")
  }
  if (kernel == "beta" & !is.null(t)) {
    stop("A beta distribution was specified, as well as the 't' parameter.
            Did you mean to choose a negative exponential distribution?")
  }

  # Negative exponential kernel
  if (kernel == "neg_exp") {
    if (is.null(t)) {
      t <- 0.2
    }
    rng <- 1:maxdist
    h <- 1 / (maxdist * t)
    y <- exp(-h * rng)
    plot(rng, y,
      main = " Negative exponential kernel",
      xlab = "Distance",
      ylab = "Probability of successful dispersal"
    )
    mtext(paste0("Parameters: t = ", t))
  }

  # Beta distribution kernel
  if (kernel == "beta") {
    if (is.null(a)) {
      a <- 3
    }
    if (is.null(b)) {
      b <- 7
    }
    rng <- 1:maxdist
    x <- rng / maxdist
    y <- dbeta(x, a, b)
    y <- y / max(y)
    plot(rng, y,
      main = "Beta distribution kernel",
      xlab = "Distance",
      ylab = "Probability of successful dispersal"
    )
    mtext(paste0("Parameters: a = ", a, ", b = ", b))
  }
}
