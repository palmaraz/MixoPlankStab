# =============================================================================
# Utility functions for MixoPlankStab analysis
# =============================================================================
# These functions support the Bayesian LVR-SSVS inverse modeling pipeline:
#   - prior_vs_posterior: visual diagnostic comparing prior and posterior
#   - MAP_Slab: extract posterior mode from spike-and-slab distributions
#   - offdiagonal: matrix helper for extracting inter-type interactions
#   - colSd, colVar: column-wise summary statistics
#   - theme_bw_cust: publication-quality ggplot2 theme
# =============================================================================

# -- Prior vs. posterior distribution diagnostic plot -------------------------
# Overlays the prior distribution (normal, spike-slab, or beta) on the
# histogram of posterior samples. Used to assess how informative the data
# are relative to the prior for interaction probabilities.

prior_vs_posterior <- function(data,
                               alpha=2, beta=8,
                               mean=0, sd=10,
                               bins = 50, xlim = c(-10, 10),
                               title = "Prior vs. posterior distribution",
                               dist = "normal",
                               legend=TRUE,
                               pos.legend="center") {

  data = as.data.frame(data)

  hist_data <- hist(data[,1], breaks = bins, plot = FALSE)
  hist_height <- max(hist_data$density)

  # Build an histogram
  hist(data[,1], breaks = bins, main = title,
       xlab = "Probability of interaction", ylab = "Density",
       col = "#6666FF", border = "#330099",
       ylim = c(0, hist_height), xlim = xlim, prob = TRUE)

  if (dist == "normal") {
    x <- seq(xlim[1],xlim[2], length = 1000)
    y <- dnorm(x, mean = mean, sd = sd)
    y <- y * hist_height / max(y)
  }

  if (dist == "spike-slab") {
    x <- seq(xlim[1],xlim[2], length = 1000)
    y <- dnorm(x, mean = mean, sd = sd) # This is the slab, a normal distribution
    y <- y * hist_height / max(y)
  }

  if (dist == "beta") {
    x <- seq(xlim[1],xlim[2], length = 1000)
    y <- dbeta(x, shape1 = alpha, shape2 = beta)
    y <- y * hist_height / max(y)
  }

  # Continuous distribution
  lines(x, y, col = "red", lwd = 1, xlim = xlim)

  if (dist == "spike-slab") {

    abline(v = 0, col = "red", lwd = 1, lty = 2) # This is the spike, a Dirac's delta at 0

    if(legend) legend(pos.legend,
                     legend = c("Posterior", "Prior slab", "Prior spike"),
                     col = c("#6666FF", "red", "red"), lwd = c(1, 1, 1), bty = "n",
                     x.intersp = 0.5, lty = c(1,1,2))

  }

  # Legend
  else{
    if(legend) legend(pos.legend, legend = c("Posterior", "Prior"),
                     col = c("#6666FF", "red"), lwd = c(1, 2), bty = "n",
                     x.intersp = 0.5, lty = 1)
  }


}

# -- MAP at the Slab ----------------------------------------------------------
# For spike-and-slab posteriors, compute the MAP or mean of non-zero values
# (the "slab" component). This isolates the posterior of interaction coefficients
# that were active during MCMC simulation, ignoring the spike (zero) mass.

MAP_Slab <- function(df, MAP=TRUE) {

  df = as.data.frame(df)

  # Apply the function to each column
  sapply(df, function(column) {
    # Filter out the values that are different from zero
    non_zero_values = column[column != 0]
    # Calculate the mean of non-zero values
    if (length(non_zero_values) > 0) {

      ifelse(MAP==TRUE, map_estimate(non_zero_values)$MAP_Estimate, mean(non_zero_values, na.rm=T))

    } else {
      0  # Return 0 if all values are zero
    }
  })
}

# -- Off-diagonal extraction ---------------------------------------------------
# Extract the off-diagonal elements of a square matrix. Used to isolate
# inter-type interaction coefficients from the alpha matrix (diagonal = self-regulation).

offdiagonal <- function(x){
  x[outer(1:dim(x)[1], 1:dim(x)[1], function(i,j) i!=j)]
}

# -- Column-wise standard deviation and variance ------------------------------

colSd = function(x, na.rm=TRUE) {apply(X=x, MARGIN=2, FUN=sd, na.rm=TRUE)}

colVar = function(df) {apply(df, MARGIN=2, FUN=var, na.rm = TRUE)}

# -- Custom B&W theme for ggplot2 ----------------------------------------------
# Clean, publication-ready theme with no gridlines and transparent background.

theme_bw_cust = theme(
  axis.line.x=element_line(linewidth=0.5,colour="Black"),
  axis.line.y=element_line(linewidth=0.5,colour="Black"),
  axis.text=element_text(size=18,colour="Black"),
  axis.title=element_text(size=18,colour="Black"),
  plot.title = element_text(size=15),
  legend.position = "right",
  legend.text = element_text(size = 12),
  legend.key = element_blank(),
  panel.grid = element_blank(),
  panel.grid.minor = element_blank(),
  panel.grid.major = element_blank(),
  panel.background = element_blank(),
  plot.background = element_rect(fill = "transparent", colour = NA))
