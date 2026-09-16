# MixoPlankStab

Code and data for the Bayesian Lotka-Volterra-Ricker model with stochastic search variable selection (LVR-SSVS) fitted to plankton biomass time series from station L4 (Western English Channel), under a mixotrophic classification and two plant-animal groupings.

<br>

## Requirements

You need R (version 4.3 or later), JAGS (version 4.3 or later), pandoc, and a TeX distribution with `pdflatex` and `bibtex`. The large binary files (`*.RData`, `*.nc`) are stored with Git LFS. Run `git lfs install` before you clone the repository.

<br>

## Licence

The code and scripts in this repository (`analysis.Rmd`, `code/`, `run_all.sh`, `build_manuscript.sh`, `install_packages.R`) are licensed under the GNU General Public License version 3 (GPL-3.0). See `LICENSE` for the full text.

<br>

## Data availability and use

The data in this repository are **not** open data and the GPL-3.0 licence does **not** apply to them. This includes the raw L4 data sets in `data/data-raw/`, the merged data set `data/data_full.csv` and the posterior samples in `output/*.RData`. You must not use, copy or redistribute these data without permission. Send all inquiries about the use of the data to:

Dr. Suzana Gonçalves Leles  
The University of Texas at Austin | Marine Science Institute  
750 Channel View Drive, Port Aransas, TX 78373  
E-mail: suzana.leles@utexas.edu

The satellite subset in `data-raw/satellite/` is a Copernicus Marine Service product and its use is subject to the Copernicus Marine Service terms of use.

<br>

## Reproduce the results

Run this command from the repository root:

```bash
INSTALL=TRUE ./run_all.sh
```

The script does these steps:

1. It installs the missing R packages (`install_packages.R`).
2. It renders `analysis.Rmd`, which merges the raw data, imputes the environmental series, loads the posterior samples, computes the stability metrics and writes the figures.
3. It runs `code/figures/fig1_compose.R`, which writes Figure 1.
4. It runs `build_manuscript.sh`, which builds the manuscript and the supporting information with `pdflatex` and `bibtex`.

By default, the script uses the posterior samples in `output/`. To refit the three JAGS models, run `REFIT=TRUE ./run_all.sh`. The refit takes several hours. To skip the LaTeX build, run `BUILD_MS=FALSE ./run_all.sh`. To build only the manuscript after the analyses are finished, run `./build_manuscript.sh`.

<br>

## Outputs

| Location | Content |
|---|---|
| `analysis.html` | Full analysis report |
| `data/data_full.csv` | Merged data set |
| `output/figs/`, `output/nonmixo_*/figs/` | All diagnostic figures |
| `output/imputation/`, `output/nonmixo_*/imputation/` | Imputation plots |
| `manuscript/figs/` | All figures of the manuscript and the supporting information |
| `manuscript/Almaraz_etal_ELE_2026.pdf` | Manuscript |
| `manuscript/SI/Almaraz_etal_ELE_2026_supporting_information.pdf` | Supporting information |

The food web schematic (`manuscript/figs/foodwebs.jpg`) is a drawn figure and the code does not make it.

<br>

## Repository layout

| Path | Content |
|---|---|
| `analysis.Rmd` | Analysis pipeline |
| `code/process_data.R` | Merge of the raw L4 data sets |
| `code/functions.R` | Helper functions |
| `code/LVR_SSVS_JAGS.R` | JAGS model |
| `code/figures/` | Figure 1 scripts |
| `data/data-raw/` | Raw L4 data (flow cytometry, protists, mesozooplankton, nutrients, chlorophyll, mixed layer depth, temperature) |
| `data/silhouettes/` | Silhouettes and network legends |
| `data-raw/satellite/` | Copernicus Marine chlorophyll-a subset for Figure 1A |
| `output/*.RData` | Posterior samples of the three fitted models |
| `manuscript/` | LaTeX sources, bibliographies, figures and PDFs of the manuscript (`manuscript/SI/` holds the supporting information) |
| `LICENSE` | GNU GPL version 3 (code only) |
| `data/DATA_NOTICE.md` | Terms of use of the data |
