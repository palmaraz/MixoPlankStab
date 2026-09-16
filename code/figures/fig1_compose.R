# ============================ #
# Figure 1: compose and save ####
# ============================ #
#
# Composes panels A (Copernicus Marine chlorophyll-a study area), B-D
# (functional-type biomass time series grouped by trophic strategy),
# and E (environmental drivers) into a PNAS single-column figure
# (3.4 in wide). The composite carries NO outer caption; the figure
# caption lives entirely in the LaTeX `\caption{}` block.
#
# Outputs:
#   manuscript/figs/Fig1_study_area_timeseries.png   (600 dpi, ragg)
#   manuscript/figs/Fig1_study_area_timeseries.pdf   (vector, cairo_pdf)
#
# If the Copernicus Marine NetCDF has not been downloaded yet, the
# script falls back to a time-series-only preview saved next to the
# final outputs as Fig1_preview_timeseries_only.{png,pdf}, and prints
# the exact CLI command needed to fetch the satellite scene.

suppressPackageStartupMessages({
  library(here)
  library(patchwork)
  library(ggplot2)
  library(ragg)
  library(grDevices)
})

source(here::here("code", "figures", "fig1_study_area.R"))
source(here::here("code", "figures", "fig1_timeseries.R"))

d <- load_l4()

C_auto   <- build_ft_panel(d, FTS$autotrophs,   "D", "C  Autotrophs")
D_mixo   <- build_ft_panel(d, FTS$mixotrophs,   "C", "D  Mixotrophs")
E_hetero <- build_ft_panel(d, FTS$heterotrophs, "F", "E  Heterotrophs")
B_env    <- build_env_panel(d)

nc_path <- NC_DEFAULT
have_nc <- file.exists(nc_path)

W_DOUBLE <- 7.0
H_HALF   <- 6.5
H_LEFT   <- c(A = 3.7, B = 2.8)
H_RIGHT  <- c(C = 1.7, D = 2.4, E = 2.4)

OUTER_THEME <- ggplot2::theme(plot.margin = ggplot2::margin(0, 0, 0, 0))

if (have_nc) {
  A <- build_fig1A(nc_path)
  left  <- (A / B_env) +
    patchwork::plot_layout(heights = unname(H_LEFT))
  right <- (C_auto / D_mixo / E_hetero) +
    patchwork::plot_layout(heights = unname(H_RIGHT))
  fig1  <- (left | patchwork::plot_spacer() | right) +
    patchwork::plot_layout(widths = c(1, 0.03, 1)) +
    patchwork::plot_annotation(theme = OUTER_THEME)
  out_png <- here::here("manuscript", "figs", "Fig1_study_area_timeseries.png")
  out_pdf <- here::here("manuscript", "figs", "Fig1_study_area_timeseries.pdf")
  w <- W_DOUBLE; h <- H_HALF
} else {
  fig1 <- (B_env | patchwork::plot_spacer() | (C_auto / D_mixo / E_hetero)) +
    patchwork::plot_layout(widths = c(1, 0.03, 1)) +
    patchwork::plot_annotation(theme = OUTER_THEME)
  out_png <- here::here("manuscript", "figs", "Fig1_preview_timeseries_only.png")
  out_pdf <- here::here("manuscript", "figs", "Fig1_preview_timeseries_only.pdf")
  w <- W_DOUBLE; h <- H_HALF
  message("\n[fig1_compose.R] Satellite NetCDF not found at:")
  message("  ", nc_path)
  message("Fetch it once with:")
  message("  pip install copernicusmarine && copernicusmarine login")
  message("  copernicusmarine subset \\")
  message("    --dataset-id cmems_obs-oc_atl_bgc-plankton_my_l4-multi-1km_P1M \\")
  message("    --variable CHL \\")
  message("    --start-datetime 2007-04-01 --end-datetime 2014-04-30 \\")
  message("    --minimum-longitude -6.0 --maximum-longitude -2.5 \\")
  message("    --minimum-latitude 49.5 --maximum-latitude 51.0 \\")
  message("    --output-directory data-raw/satellite \\")
  message("    --output-filename CMEMS_chla_NEA_AprMay_2007_2014.nc")
  message("Then re-run this script to obtain the full Figure 1.\n")
}

ragg::agg_png(out_png, width = w, height = h, units = "in",
              res = 600, background = "white")
print(fig1)
invisible(dev.off())

grDevices::cairo_pdf(out_pdf, width = w, height = h, bg = "white")
print(fig1)
invisible(dev.off())

message("Wrote: ", out_png)
message("Wrote: ", out_pdf)
