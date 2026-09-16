# =============================================================================
# Merging L4 datasets into a single analysis-ready data frame
# =============================================================================
#
# Data sources:
#   - Flow cytometry: bacteria, picophytoplankton, NanoCMs, nanozooplankton
#   - Microscopy: diatoms, MicroCMs, GNCMs, SNCMs, microzooplankton
#   - Vertical hauls: mesozooplankton
#   - Nutrients: nitrate, ammonium, silicate, phosphate (surface, 0 m)
#   - Chlorophyll-a (10 m depth)
#   - Mixed layer depth (modelled)
#   - Temperature (surface, 0 m)
#
# Depth: all functional types at 10 m except mesozooplankton (vertical hauls).
# Period: 2006 onwards (ciliate taxonomy unreliable before this date).
#
# Output: data_full (data frame in the global environment)
# =============================================================================

build_data_full <- function() {

  # -- Flow cytometry biomass (ug C / L) -------------------------------------
  # bacteria, picophytoplankton, nanoCMs, nanozooplankton
  # 04/2007 - 12/2016
  datab <- read.table("data/data-raw/data_flow_cytometry.txt", header = TRUE)
  datab <- subset(datab, depth >= 9 & depth <= 11)
  datab$date <- as.Date(datab$date, format = "%d/%m/%y")
  datab$depth <- NULL

  # -- Mesozooplankton biomass (ug C / L, vertical hauls) --------------------
  # 01/2006 - 12/2017
  datam <- read.table("data/data-raw/data_mesozoo.txt", header = TRUE)
  datam$date <- as.Date(datam$date, format = "%d/%m/%Y")

  # -- Protist microscopy biomass (ug C / L, 10 m) ---------------------------
  # diatoms, MicroCMs, GNCMs, SNCMs, microzooplankton
  # 10/1992 - 12/2015
  datap <- read.table("data/data-raw/data_protists.txt", header = TRUE)
  datap$date <- as.Date(datap$date, format = "%d/%m/%Y")

  # -- Inorganic nutrients (uM, surface 0 m) ---------------------------------
  # nitrate, ammonium, silicate, phosphate
  # 01/2000 - 09/2017
  datan <- read.table("data/data-raw/data_nutrients.txt", header = TRUE, na.strings = "NA")
  datan$date <- as.Date(datan$date, format = "%d/%m/%Y")
  datan <- subset(datan, depth == 0)
  datan$depth <- NULL
  datan$nitrite <- NULL
  datan <- plyr::ddply(datan, .(date), plyr::colwise(mean, na.rm = TRUE))

  # -- Chlorophyll-a (ug / L) ------------------------------------------------
  # 02/2007 - 08/2017
  datachl <- read.table("data/data-raw/data_chl.txt", header = TRUE)
  datachl$date <- as.Date(datachl$date, format = "%d/%m/%Y")
  datachl$depth <- NULL

  # -- Mixed layer depth (m, modelled) ----------------------------------------
  # 01/2006 - 12/2014
  datamld <- read.table("data/data-raw/data_mld.txt", header = TRUE)
  datamld$date <- as.Date(datamld$date)
  datamld$month <- NULL
  datamld$year <- NULL

  # -- Temperature (C, surface 0 m) -------------------------------------------
  datatemp <- read.table("data/data-raw/temp_prof_2002_2016_0m.txt", header = TRUE)
  datatemp$date <- as.Date(datatemp$date, format = "%Y-%m-%d")

  # -- Merge all datasets by date --------------------------------------------
  df <- dplyr::inner_join(datatemp, datamld, by = "date")
  df <- dplyr::inner_join(df, datachl, by = "date")
  df <- dplyr::inner_join(df, datan,   by = "date")
  df <- dplyr::inner_join(df, datab,   by = "date")
  df <- dplyr::inner_join(df, datap,   by = "date")
  df <- dplyr::inner_join(df, datam,   by = "date")

  # -- Fix duplicated row (rows 115-116 differ only in mesozoo) ---------------
  meso_avg <- (df[115, "mesozoo"] + df[116, "mesozoo"]) / 2
  df[116, "mesozoo"] <- meso_avg
  df <- df[-115, ]

  # -- Temporal variables -----------------------------------------------------
  df$Days_seq <- as.numeric(as.Date(df$date)) - 13625
  df$dt <- c(NA, diff(df$Days_seq))
  df <- df %>% tidyr::separate(date, sep = "-", into = c("year", "month", "day"))

  # -- Clean NaN -> NA --------------------------------------------------------
  df <- df %>% dplyr::mutate(dplyr::across(dplyr::everything(),
                                            ~ ifelse(is.nan(.), NA, .)))

  # -- Save to disk -----------------------------------------------------------
  write.table(df, "data/data_full.csv", sep = ";")

  df
}

# Execute and assign to global environment
data_full <- build_data_full()
