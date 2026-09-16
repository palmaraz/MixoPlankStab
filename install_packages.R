# ============================ #
# Install R dependencies ####
# ============================ #

cran <- c("rmarkdown", "knitr", "htmltools", "here", "devtools",
          "data.table", "imputeTS", "ggridges", "viridis", "expm", "plyr",
          "dplyr", "tidyverse", "runjags", "coda", "bayestestR", "bayesplot",
          "patchwork", "psych", "MASS", "mvtnorm", "qgraph", "ggmcmc", "png",
          "foreach", "doParallel", "figpatch", "ggpubr", "reshape2",
          "terra", "tidyterra", "sf", "rnaturalearth", "ggspatial", "ggrepel",
          "cowplot", "ragg", "lubridate", "scales", "stringr", "tidyr")

missing <- cran[!vapply(cran, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) install.packages(missing)

# High-resolution coastline used by rnaturalearth::ne_countries(scale = "large")
if (!requireNamespace("rnaturalearthhires", quietly = TRUE))
  install.packages("rnaturalearthhires",
                   repos = c("https://ropensci.r-universe.dev", getOption("repos")))
