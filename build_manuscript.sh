#!/usr/bin/env bash
# Build the manuscript and the supporting information in manuscript/.
# The figures are written to manuscript/figs/ by run_all.sh.
#
# Usage:
#   ./build_manuscript.sh
#
# Requirements: pdflatex and bibtex (TeX Live or equivalent).

set -euo pipefail
cd "$(dirname "$0")"

command -v pdflatex >/dev/null || { echo "pdflatex not found" >&2; exit 1; }
command -v bibtex   >/dev/null || { echo "bibtex not found" >&2; exit 1; }

FIGS="Fig1_study_area_timeseries.pdf foodwebs.jpg Main_timeseries.pdf
Interaction_networks_wlegend.pdf Wrapped_stability.pdf Stab_plot_compare.pdf
Environmental_data.pdf PPC_TS_fullplot.pdf bayes_factors.pdf Environmental_effects.pdf Env_cov_spring.pdf
Interaction_networks_wlegend_nonmixo_1.pdf Wrapped_stability_nonmixo_1.pdf PPC_TS_fullplot_nonmixo1.pdf bayes_factors_nonmixo_1.pdf
Interaction_networks_wlegend_nonmixo_2.pdf Wrapped_stability_nonmixo_2.pdf PPC_TS_fullplot_nonmixo2.pdf bayes_factors_nonmixo_2.pdf"

for f in $FIGS; do
  [ -f "manuscript/figs/$f" ] || { echo "Missing figure manuscript/figs/$f (run ./run_all.sh first)" >&2; exit 1; }
done

build () {
  ( cd "$1"
    pdflatex -interaction=nonstopmode -halt-on-error "$2" >/dev/null
    bibtex "$2" >/dev/null
    pdflatex -interaction=nonstopmode -halt-on-error "$2" >/dev/null
    pdflatex -interaction=nonstopmode -halt-on-error "$2" >/dev/null
    rm -f "$2".aux "$2".log "$2".bbl "$2".blg "$2".out "$2".synctex.gz
    echo "Wrote: $1/$2.pdf" )
}

build manuscript    Almaraz_etal_ELE_2026
build manuscript/SI Almaraz_etal_ELE_2026_supporting_information
