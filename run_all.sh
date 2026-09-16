#!/usr/bin/env bash
# Rebuild every output and figure of the MixoPlankStab analysis.
#
# Usage:
#   ./run_all.sh              # reuse the stored posterior samples in output/
#   REFIT=TRUE ./run_all.sh   # refit the three JAGS models (several hours)
#   INSTALL=TRUE ./run_all.sh # install missing R packages first
#   BUILD_MS=FALSE ./run_all.sh # skip the LaTeX build of the manuscript
#
# Requirements: R (>= 4.3), JAGS (>= 4.3), pandoc.

set -euo pipefail
cd "$(dirname "$0")"

REFIT="${REFIT:-FALSE}"
INSTALL="${INSTALL:-FALSE}"
BUILD_MS="${BUILD_MS:-TRUE}"

command -v Rscript >/dev/null || { echo "Rscript not found" >&2; exit 1; }
command -v jags    >/dev/null || { echo "JAGS not found" >&2; exit 1; }

if [ "$INSTALL" = "TRUE" ]; then
  Rscript install_packages.R
fi

# Output folders written by the pipeline
mkdir -p output/figs output/imputation \
         output/nonmixo_1/figs output/nonmixo_1/imputation \
         output/nonmixo_2/figs output/nonmixo_2/imputation \
         manuscript/figs

# Network legends read by the pipeline from the output folders
cp data/silhouettes/Network_legend.png          output/figs/
cp data/silhouettes/Network_legend_arrows.png   output/figs/
cp data/silhouettes/Network_legend_nonmixo1.png output/nonmixo_1/figs/
cp data/silhouettes/Network_legend_arrows.png   output/nonmixo_1/figs/
cp data/silhouettes/Network_legend_nonmixo2.png output/nonmixo_2/figs/
cp data/silhouettes/Network_legend_arrows.png   output/nonmixo_2/figs/

if [ "$REFIT" != "TRUE" ]; then
  for f in output/LVR_Gibbs_SSVS.RData \
           output/nonmixo_1/LVR_Gibbs_SSVS_nm1.RData \
           output/nonmixo_2/LVR_Gibbs_SSVS_nm2.RData; do
    [ -f "$f" ] || { echo "Missing posterior file $f (run 'git lfs pull' or set REFIT=TRUE)" >&2; exit 1; }
  done
fi

echo "== 1/3 Analysis pipeline (analysis.Rmd, refit_model = $REFIT)"
Rscript -e "rmarkdown::render('analysis.Rmd', params = list(refit_model = $REFIT, save_figs = TRUE))"

echo "== 2/3 Figure 1 (study area and time series)"
Rscript code/figures/fig1_compose.R

if [ "$BUILD_MS" = "TRUE" ]; then
  echo "== 3/3 Manuscript and supporting information (LaTeX)"
  ./build_manuscript.sh
fi

echo "== Done. Diagnostic figures in output/; manuscript figures and PDFs in manuscript/"
