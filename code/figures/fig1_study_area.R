# ============================ #
# Figure 1A: study-area map ####
# ============================ #
#
# Builds the Sentinel-3 OLCI / Copernicus Marine multi-sensor chlorophyll-a
# panel centred on station L4 (Western Channel Observatory, 50.25 N, 4.22 W).
#
# Source NetCDF must be downloaded once via the Copernicus Marine Toolbox
# (the script does NOT touch the network; this download is a one-off step):
#
#   pip install copernicusmarine
#   copernicusmarine login                                    # interactive
#   copernicusmarine subset \
#     --dataset-id cmems_obs-oc_atl_bgc-plankton_my_l4-multi-1km_P1M \
#     --variable CHL \
#     --start-datetime 2007-04-01 --end-datetime 2014-04-30 \
#     --minimum-longitude -7.0 --maximum-longitude -2.0 \
#     --minimum-latitude 48.5 --maximum-latitude 52.0 \
#     --output-directory data-raw/satellite \
#     --output-filename CMEMS_chla_NEA_AprMay_2007_2014.nc
#
# The figure script computes the April climatology over 2007-2014 and
# clips to the Western English Channel bounding box. The panel carries no
# in-figure subtitle or caption; all explanatory text lives in the LaTeX
# `\caption{}` block of the manuscript.

suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(tidyterra)
  library(sf)
  library(rnaturalearth)
  library(ggspatial)
  library(ggplot2)
  library(ggrepel)
  library(cowplot)
  library(viridis)
})

NC_DEFAULT <- here::here("data-raw", "satellite",
                         "CMEMS_chla_NEA_AprMay_2007_2014.nc")

build_fig1A <- function(nc_path = NC_DEFAULT,
                        bbox = c(xmin = -6.16, xmax = -2.5,
                                 ymin = 49.0, ymax = 51.5),
                        l4 = c(lon = -4.217, lat = 50.25),
                        target_month = 4L) {

  if (!file.exists(nc_path)) {
    stop("Satellite NetCDF not found at:\n  ", nc_path,
         "\nDownload it with the copernicusmarine CLI; see header of ",
         "code/figures/fig1_study_area.R.", call. = FALSE)
  }

  chl <- terra::rast(nc_path)
  layer_months <- as.integer(format(terra::time(chl), "%m"))
  target_layers <- which(layer_months == target_month)
  if (length(target_layers) == 0L) {
    stop("No layers in the NetCDF match month = ", target_month, ".",
         call. = FALSE)
  }
  chl_clim <- terra::app(chl[[target_layers]], fun = mean, na.rm = TRUE)
  names(chl_clim) <- "chl"

  coast <- rnaturalearth::ne_countries(scale = "large", returnclass = "sf")
  europe <- rnaturalearth::ne_countries(scale = "medium",
                                        continent = "europe",
                                        returnclass = "sf")

  l4_df <- data.frame(lon = unname(l4["lon"]),
                      lat = unname(l4["lat"]),
                      lab = "L4")

  lon_span <- bbox[["xmax"]] - bbox[["xmin"]]
  lat_span <- bbox[["ymax"]] - bbox[["ymin"]]

  lat_breaks <- c(49.5, 50.0, 50.5, 51.0)
  lon_breaks <- c(-6.0, -5.0, -4.0)

  lat_labels_df <- data.frame(
    lon = bbox[["xmin"]] + 0.018 * lon_span,
    lat = lat_breaks,
    label = paste0(format(lat_breaks, nsmall = 1), "°N")
  )
  lon_labels_df <- data.frame(
    lon = lon_breaks,
    lat = bbox[["ymin"]] + 0.020 * lat_span,
    label = paste0(format(abs(lon_breaks), nsmall = 1), "°W")
  )

  km_per_lon_deg <- 111.32 * cos(50.25 * pi / 180)
  scale_km  <- 60
  scale_deg <- scale_km / km_per_lon_deg
  scale_xmin <- bbox[["xmin"]] + 0.04 * lon_span
  scale_xmax <- scale_xmin + scale_deg
  scale_y    <- bbox[["ymin"]] + 0.10 * lat_span
  tick_h     <- 0.012 * lat_span
  text_yoff  <- 0.020 * lat_span

  main <- ggplot() +
    tidyterra::geom_spatraster(data = chl_clim) +
    geom_sf(data = coast, fill = "grey90", colour = "grey30",
            linewidth = 0.25) +
    geom_point(data = l4_df, aes(x = lon, y = lat),
               shape = 21, fill = "white", colour = "black",
               size = 2.6, stroke = 0.8) +
    ggrepel::geom_text_repel(data = l4_df,
                             aes(x = lon, y = lat, label = lab),
                             nudge_x = 0.22, nudge_y = 0.14,
                             colour = "black", size = 3.0,
                             fontface = "bold",
                             segment.colour = "black",
                             segment.size = 0.3,
                             min.segment.length = 0) +
    geom_label(data = lat_labels_df,
               aes(x = lon, y = lat, label = label),
               hjust = 0, vjust = 0.5, size = 1.9, colour = "black",
               fill = scales::alpha("white", 0.85),
               label.padding = unit(1.0, "pt"),
               label.r = unit(0, "pt"),
               linewidth = 0) +
    geom_label(data = lon_labels_df,
               aes(x = lon, y = lat, label = label),
               hjust = 0.5, vjust = 0, size = 1.9, colour = "black",
               fill = scales::alpha("white", 0.85),
               label.padding = unit(1.0, "pt"),
               label.r = unit(0, "pt"),
               linewidth = 0) +
    annotate("segment",
             x = scale_xmin, xend = scale_xmax,
             y = scale_y, yend = scale_y,
             colour = "white", linewidth = 0.8) +
    annotate("segment",
             x = scale_xmin, xend = scale_xmin,
             y = scale_y - tick_h, yend = scale_y + tick_h,
             colour = "white", linewidth = 0.8) +
    annotate("segment",
             x = scale_xmax, xend = scale_xmax,
             y = scale_y - tick_h, yend = scale_y + tick_h,
             colour = "white", linewidth = 0.8) +
    annotate("text",
             x = (scale_xmin + scale_xmax) / 2,
             y = scale_y + text_yoff,
             label = paste0(scale_km, " km"),
             colour = "white", size = 2.2, fontface = "bold",
             vjust = 0) +
    coord_sf(xlim = c(bbox[["xmin"]], bbox[["xmax"]]),
             ylim = c(bbox[["ymin"]], bbox[["ymax"]]),
             expand = FALSE) +
    scale_fill_viridis_c(
      option = "G", trans = "log10", na.value = NA,
      name = expression("Chl-a"~(mg~m^{-3})),
      guide = guide_colorbar(direction = "vertical",
                             title.position = "top",
                             title.hjust = 0,
                             barwidth  = unit(0.28, "cm"),
                             barheight = unit(2.4, "cm"))
    ) +
    labs(x = NULL, y = NULL, subtitle = "A  Study area\n") +
    theme_minimal(base_size = 8) +
    theme(panel.background = element_rect(fill = "grey95", colour = NA),
          panel.border = element_rect(colour = "grey25",
                                      fill = NA, linewidth = 0.3),
          panel.grid = element_blank(),
          plot.subtitle = element_text(size = 8, face = "bold",
                                       margin = margin(0, 0, 1, 0)),
          plot.title = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank(),
          axis.title = element_blank(),
          legend.position = c(0.985, 0.025),
          legend.justification = c(1, 0),
          legend.title = element_text(size = 6.5),
          legend.text = element_text(size = 5.5),
          legend.background = element_rect(fill = "white",
                                           colour = "grey55",
                                           linewidth = 0.25),
          legend.margin = margin(3, 4, 3, 4),
          legend.key.height = unit(0.30, "cm"),
          plot.margin = margin(0, 0, 0, 0))

  inset <- ggplot() +
    geom_sf(data = europe, fill = "grey80", colour = "grey45",
            linewidth = 0.15) +
    geom_rect(aes(xmin = bbox[["xmin"]], xmax = bbox[["xmax"]],
                  ymin = bbox[["ymin"]], ymax = bbox[["ymax"]]),
              fill = NA, colour = "red", linewidth = 0.6) +
    coord_sf(xlim = c(-12, 6), ylim = c(43, 58), expand = FALSE) +
    theme_void() +
    theme(panel.background = element_rect(fill = "white",
                                          colour = "grey40",
                                          linewidth = 0.3),
          plot.margin = margin(0, 0, 0, 0))

  cowplot::ggdraw(main) +
    cowplot::draw_plot(inset, x = 0.74, y = 0.66,
                       width = 0.22, height = 0.22)
}
