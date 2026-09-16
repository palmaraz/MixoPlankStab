# ============================ #
# Figure 1B-E: time series ####
# ============================ #
#
# Reads data/data_full.csv (semicolon-separated, English-style decimal,
# leading row-number column auto-detected by read.csv) and returns four
# ggplot objects: autotrophs, mixotrophs, heterotrophs, environmental
# drivers. Sized for a PNAS single-column layout (~3.4 in wide). The
# panels carry only an in-figure tag-and-name subtitle; all narrative
# context lives in the LaTeX `\caption{}` block of the manuscript.

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(scales)
  library(stringr)
  library(ggplot2)
  library(viridis)
})

FTS <- list(
  autotrophs   = c("picop", "diatoms"),
  mixotrophs   = c("nanocms", "microcms", "gncms", "sncms"),
  heterotrophs = c("bact", "nanozoo", "microzoo", "mesozoo")
)

FT_LABELS <- c(
  bact     = "Bacteria",
  picop    = "Picoplankton",
  nanozoo  = "Nanozooplankton",
  nanocms  = "NanoCMs",
  diatoms  = "Diatoms",
  microcms = "MicroCMs",
  gncms    = "GNCMs",
  sncms    = "SNCMs",
  microzoo = "Microzooplankton",
  mesozoo  = "Mesozooplankton"
)

ENV_VARS <- c("temp", "mld", "chl", "nitrate", "ammonium",
              "silicate", "phosphate")

ENV_LABELS <- c(
  temp      = "Temperature (°C)",
  mld       = "Mixed-layer depth (m)",
  chl       = "Chl-a (µg L⁻¹)",
  nitrate   = "Nitrate (µM)",
  ammonium  = "Ammonium (µM)",
  silicate  = "Silicate (µM)",
  phosphate = "Phosphate (µM)"
)

ENV_COLOURS <- c(
  temp      = "#E69F00",
  mld       = "#56B4E9",
  chl       = "#009E73",
  nitrate   = "#0072B2",
  ammonium  = "#CC79A7",
  silicate  = "#D55E00",
  phosphate = "#7F3F98"
)

load_l4 <- function(path = here::here("data", "data_full.csv")) {
  d <- utils::read.csv(path, sep = ";", dec = ".",
                       stringsAsFactors = FALSE, na.strings = "NA")
  d$Date <- lubridate::make_date(d$year, d$month, d$day)
  d
}

build_ft_panel <- function(d, vars, palette_option, panel_subtitle) {
  vars_present <- vars[
    vapply(vars, function(v) any(is.finite(d[[v]]) & d[[v]] > 0), logical(1))
  ]

  if (length(vars_present) == 0L) {
    return(
      ggplot() +
        annotate("text", x = 0.5, y = 0.5,
                 label = paste0(panel_subtitle, ": not quantified at this site"),
                 size = 2, hjust = 0.5) +
        theme_void() +
        xlim(0, 1) + ylim(0, 1)
    )
  }

  long <- d %>%
    dplyr::select(Date, dplyr::all_of(vars_present)) %>%
    tidyr::pivot_longer(-Date, names_to = "ft_code", values_to = "biomass") %>%
    dplyr::filter(is.finite(biomass), biomass > 0) %>%
    dplyr::mutate(ft = factor(ft_code, levels = vars_present,
                              labels = FT_LABELS[vars_present]))

  pal <- viridis::viridis_pal(option = palette_option,
                              begin = 0.10, end = 0.85)(length(vars_present))
  names(pal) <- FT_LABELS[vars_present]

  legend_rows <- if (length(vars_present) <= 2L) 1L else 2L

  ggplot(long, aes(x = Date, y = biomass, colour = ft)) +
    geom_line(linewidth = 0.30, alpha = 0.95) +
    scale_y_log10(labels = scales::label_log()) +
    scale_x_date(date_breaks = "2 years", date_labels = "%Y",
                 expand = expansion(mult = c(0.01, 0.03))) +
    scale_colour_manual(values = pal, name = NULL,
                        guide = guide_legend(nrow = legend_rows,
                                             keywidth = unit(0.35, "cm"),
                                             keyheight = unit(0.20, "cm"))) +
    labs(x = NULL,
         y = expression("µg C L"^{-1}),
         subtitle = panel_subtitle) +
    theme_bw(base_size = 7) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major.x = element_line(colour = "grey92"),
          plot.subtitle = element_text(size = 8, face = "bold",
                                       margin = margin(0, 0, 1, 0)),
          legend.position = "top",
          legend.justification = "right",
          legend.box.margin = margin(-2, 0, -4, 0),
          legend.spacing.x = unit(0.12, "cm"),
          legend.text = element_text(size = 6.5),
          legend.background = element_blank(),
          axis.title.y = element_text(size = 7, angle = 90,
                                      margin = margin(0, 2, 0, 0)),
          axis.text = element_text(size = 6),
          plot.margin = margin(1, 3, 1, 4))
}

build_env_panel <- function(d) {
  wrapped <- stringr::str_wrap(ENV_LABELS, width = 12)
  names(wrapped) <- names(ENV_LABELS)

  long <- d %>%
    dplyr::select(Date, dplyr::all_of(ENV_VARS)) %>%
    tidyr::pivot_longer(-Date, names_to = "var_code",
                        values_to = "value") %>%
    dplyr::filter(is.finite(value)) %>%
    dplyr::mutate(var = factor(var_code, levels = ENV_VARS,
                               labels = wrapped[ENV_VARS]))

  pal <- ENV_COLOURS[ENV_VARS]
  names(pal) <- wrapped[ENV_VARS]

  ggplot(long, aes(x = Date, y = value, colour = var)) +
    geom_point(size = 0.22, alpha = 0.45) +
    geom_line(linewidth = 0.30, alpha = 0.90) +
    facet_grid(rows = dplyr::vars(var),
               scales = "free_y", switch = "y") +
    scale_colour_manual(values = pal, guide = "none") +
    scale_x_date(date_breaks = "2 years", date_labels = "%Y",
                 expand = expansion(mult = c(0.01, 0.03))) +
    scale_y_continuous(n.breaks = 3) +
    labs(x = NULL, y = NULL,
         subtitle = "\nB  Environmental drivers") +
    theme_bw(base_size = 7) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major.x = element_line(colour = "grey92"),
          panel.spacing.y = unit(0.15, "lines"),
          strip.background = element_blank(),
          strip.placement = "outside",
          strip.text.y.left = element_text(size = 6.5, face = "bold",
                                           angle = 0, hjust = 1,
                                           lineheight = 0.85,
                                           margin = margin(0, 3, 0, 0)),
          plot.subtitle = element_text(size = 8, face = "bold",
                                       margin = margin(0, 0, 1, 0)),
          axis.text.y = element_text(size = 5.5),
          axis.text.x = element_text(size = 6),
          plot.margin = margin(0, 0, 1, 0))
}
