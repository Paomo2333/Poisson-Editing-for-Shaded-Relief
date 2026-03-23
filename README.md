# Poisson Editing for Shaded Relief

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MATLAB](https://img.shields.io/badge/Made_with-MATLAB-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Python](https://img.shields.io/badge/Made_with-Python-1f425f.svg)](https://www.python.org/)

> **Official Repository for the paper:** > *"Enhancing Topographic Mapping Using Relief Shading: A Case Study of the Larsemann Hills, East Antarctica"*

## 📖 1. Overview

This repository implements and documents a Poisson‑editing‑based shaded relief workflow designed to enhance topographic maps, particularly in low‑ to moderate‑relief terrains such as glaciers. 

Our approach generates multi‑directional hillshades from a Digital Elevation Model (DEM), fuses them using iterative Poisson editing, and produces high‑quality shaded reliefs optimized for geomorphological interpretation.

The repository is organized into modular MATLAB and Python scripts that handle the complete pipeline:
* **Correcting dome artifacts** in UAV‑derived DEMs.
* **Generalizing DEMs** with Line Integral Convolution (LIC).
* **Fusing multi‑azimuth hillshades** via Poisson editing.
* **Performing mask‑based classification** of geomorphological units.
* **Validating and optimizing DEM elevations** against ICESat‑2 along‑track data.

Each module can be run independently or chained together for an end-to-end workflow.

---

## 📂 2. Repository Structure

```text
Poisson-Editing-for-Shaded-Relief/
├── README.md
└── Reliefshading_Github/
    ├── 1_Dome_profile/
    ├── 2_LIC_Generalization/
    ├── 3_Reliefshading/
    ├── 4_Mask_Classification/
    ├── 5_ICESat_Optimization/
    └── 6_ReliefAnalysis/
```

### 2.1 `1_Dome_profile` – UAV DEM Optimization
Assesses and corrects dome‑shaped systematic errors often found in Structure‑from‑Motion (SfM) DEMs.
* **`fit_dome_effect_surface.m`**: Fits a quadratic surface to sample points (e.g., `sample.xls`) to model the dome effect, computes RMSE against validation points (e.g., `validation1.xls`), and outputs a corrected DEM alongside informative figures.
* **`profile_line.m`**: Loads pairs of raw and detrended profile lines to produce multi‑panel plots for visual comparison.
* *Note: Example input data are provided under this directory (`ErrorLine/Line*.csv`, `No_errorLine/No_line*.csv`, `sample.xls`, and `validation1.xls`).*

### 2.2 `2_LIC_Generalization` – DEM Generalization with LIC
Generalizes DEMs and generates smoothed hillshades via Line Integral Convolution.
* **`run_LIC_hillshade_comparison.m`**: Orchestrates the LIC workflow. It loads a DEM, applies LIC with various kernel lengths, generates hillshades, and compares them.
* **`line_integral_convolution.m`**: Implements the LIC algorithm.
* **`generate_hillshade.m`**: A helper function for hillshade calculation.
* *Note: Adjust the `projectRoot` and `dataDir` variables at the top of these scripts to match your local data layout.*

### 2.3 `3_Reliefshading` – Poisson Hillshade Fusion
**[Core Module]** Performs iterative Poisson editing to fuse multiple hillshades.
* **`Poisson_hillshade.m`**: The main pipeline. Reads hillshades from multiple azimuths (e.g., 300°, 45°), normalizes and sanitizes them, performs two‑stage Poisson fusion, and exports fused GeoTIFFs and preview figures.
* **`Poisson_edit.m`**: The internal Gauss–Seidel Poisson solver.
* **`sanitizeHillshade.m` / `minmaxNormalize.m`**: Hillshade sanitization and normalization functions.
* **`writeGeoTiffSafe.m`**: Helper script to safely export GeoTIFFs.
* **`FigurePlotTime.m`**: Script for runtime analysis and sensitivity plotting.
* *Note: Ensure your input hillshades follow the expected naming convention described in the script comments.*

### 2.4 `4_Mask_Classification` – Mask‑Based Classification
Creates classification maps from ratio or index rasters (e.g., IOR).
* **`plot_IOR_classification.m`**: Reads a ratio raster, plots the spatial distribution, generates a histogram and a binary classification (e.g., snow vs. bare rock), and exports a high‑resolution PNG.

### 2.5 `5_ICESat_Optimization` – ICESat‑2 Accuracy Assessment & Optimization
A Python‑based module to cross‑validate DEM elevations against ICESat‑2 ATL06 data.
* **`optimization_utils.py`**: Utility functions for loading ICESat‑2 ATL06 CSVs/HDF5 files, projecting them to your DEM CRS, clipping DEMs, sampling DEM values at ICESat points, computing error metrics, and building profile plots.
* **`ICESat_Accuracy_Optimization.ipynb`**: A Jupyter Notebook demonstrating how to use `optimization_utils.py` to optimize a DEM using ICESat‑2 data.
* **`REMA_DEM_Check.ipynb`**: A Notebook comparing your DEM with the REMA reference DEM, performing bias correction, and generating basic statistics.
* *Note: This module evaluates the improvement from the dome‑effect correction and Poisson fusion relative to independent laser altimetry.*

### 2.6 `6_ReliefAnalysis` – Relief Analysis and Evaluation
Provides tools for analyzing the shaded relief and derived surfaces produced by previous modules to support interpretation and quality assessment.
* **Relief Metric Computation**: Functions to derive slope, aspect, curvature, roughness, or hypsometric curves from DEMs or smoothed surfaces.
* **Statistical Comparison**: Scripts to compare fused hillshades against reference data, compute pixel-level differences, and produce scatter plots.
* **Visualization**: Helper routines to plot relief metrics and generate publication‑ready figures.

---

## 💻 3. Environment Requirements

### MATLAB (Modules 1–4)
* **Version:** R2022a or later recommended.
* **Required Toolboxes:**
    * Image Processing Toolbox (for reading/writing images and operations).
    * Mapping Toolbox (for `readgeoraster`, `geotiffwrite`, and coordinate handling).
* **Optional:** `export_fig` (For publication‑quality figure exports; scripts safely fall back to `exportgraphics` if not installed).

### Python (Module 5)
* **Version:** Python 3.9 or later.
* **Required Packages:** `geopandas` (≥ 0.12), `rasterio` (≥ 1.3), `h5py`, `numpy`, `pandas`, `shapely`, `matplotlib`, `jupyterlab`.

**Installation Example (Conda):**
```bash
conda create -n icestools python=3.10 geopandas rasterio h5py numpy pandas matplotlib jupyterlab
conda activate icestools
```

---

## 🚀 4. Quick Start

Run each module from the repository root or adjust paths inside scripts. 

**Dome‑effect correction (MATLAB)**
```matlab
% Fit dome-effect surface and compare profiles
cd('Reliefshading_Github/1_Dome_profile');
fit_dome_effect_surface  % Outputs corrected DEM and figures
profile_line             % Generates multi-panel profile plots
```

**LIC generalization (MATLAB)**
```matlab
cd('../2_LIC_Generalization');
run_LIC_hillshade_comparison  % Creates LIC smoothed hillshades
```

**Poisson hillshade fusion (MATLAB)**
```matlab
cd('../3_Reliefshading');
Poisson_hillshade  % Reads hillshades from step 2 and performs fusion
```

**Mask classification (MATLAB)**
```matlab
cd('../4_Mask_Classification');
plot_IOR_classification  % Generates classification maps
```

**ICESat‑2 optimization (Python Terminal)**
```bash
cd Reliefshading_Github/5_ICESat_Optimization
jupyter notebook
```
*Open `ICESat_Accuracy_Optimization.ipynb` or `REMA_DEM_Check.ipynb` and follow the instructions in the first cell to set file paths.*

---

## 📁 5. Input/Output Organization

The scripts use relative paths wherever possible. Keep input and output folders separate to maintain a clean workspace:
* Place raw DEMs in a folder such as `data/DEM_Data`.
* Store sample/validation CSVs under `Reliefshading_Github/1_Dome_profile`.
* Output figures will be saved in a `figures/` directory, and processed GeoTIFFs in an `output/` or `results/` folder.

---

## ⚠️ 6. Troubleshooting

* **Missing files:** Verify that your paths to `.tif` and `.csv` inputs are correct and the directories exist.
* **`geotiffwrite` or `readgeoraster` missing:** Install the MATLAB Mapping Toolbox.
* **Formatting differences in exported figures:** If `export_fig` is missing, the fallback `exportgraphics` may render backgrounds differently. Installing `export_fig` is recommended.
* **Long runtime during Poisson fusion:** Start with a coarse tolerance for quick testing, then refine the tolerance parameter in `Poisson_edit.m` for final outputs.
* **Python import errors:** Ensure all dependencies are installed and your conda/pip environment is activated before running the notebooks.

---

## 🙏 7. Citation and Acknowledgements

If this code aids your research, please cite the associated paper and mention that you used multi‑azimuth hillshade fusion with Poisson editing. Please indicate relevant parameter settings such as azimuth angles and solver tolerances.

This project builds upon ideas from **Geisthövel & Hurni (2018)** and integrates suggestions from subsequent reviewers regarding tie‑point cleaning and ICESat‑2 validation.

## 📄 License

Distributed under the MIT License. See the [LICENSE](LICENSE) file for more information.
