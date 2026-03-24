# Poisson Editing for Shaded Relief

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MATLAB](https://img.shields.io/badge/Made_with-MATLAB-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Python](https://img.shields.io/badge/Made_with-Python-1f425f.svg)](https://www.python.org/)

> **Official Repository for the paper:** > *"Enhancing Topographic Mapping Using Relief Shading: A Case Study of the Larsemann Hills, East Antarctica"*

## 📖 1. Overview

This repository implements a complete workflow for generating high-quality shaded relief from Digital Elevation Models (DEMs). 

The motivation for our workflow is to improve visualization and geomorphological interpretation in low- to moderate-relief terrains (e.g., glacial and periglacial environments). We achieve this by addressing common artifacts in UAV-derived DEMs, smoothing terrains using Line Integral Convolution (LIC), fusing multi-azimuth hillshades via Poisson editing, and validating the results against independent elevation data (e.g., ICESat-2).

The pipeline is split into **six modular components** that can be run independently or chained together for an end-to-end workflow:
1. **Dome-effect correction:** Identify and remove dome-shaped artifacts in UAV-derived DEMs.
2. **LIC generalization:** Smooth and generalize DEMs using Line Integral Convolution.
3. **Poisson hillshade fusion:** Fuse multi-directional hillshades using an iterative Poisson solver.
4. **Mask-based classification:** Create binary/multi-class maps from ratio or index rasters.
5. **ICESat-2 optimization:** Validate and optimize DEM elevations using laser altimetry (ICESat-2 ATL06) and high-resolution DEMs (e.g., REMA).
6. **Relief analysis:** Preprocess inputs, perform kernel-density estimation (KDE), and evaluate the statistical quality of the shaded reliefs.

---

## 📂 2. Repository Structure

```text
Poisson-Editing-for-Shaded-Relief/
├── README.md                     # A concise overview
├── README_UPDATED.md             # Expanded README with module details (this file)
└── Reliefshading_Github/
    ├── 1_Dome_profile/           # MATLAB scripts for dome-effect correction
    ├── 2_LIC_Generalization/     # MATLAB scripts for LIC-based DEM smoothing
    ├── 3_Reliefshading/          # MATLAB scripts for Poisson hillshade fusion
    ├── 4_Mask_Classification/    # MATLAB scripts for simple classification
    ├── 5_ICESat_Optimization/    # Python notebooks/utils for ICESat-2 validation
    └── 6_ReliefAnalysis/         # Python notebooks for relief analysis & evaluation
```

### 2.1 `1_Dome_profile` – UAV DEM Optimization
**Goal:** Remove dome-shaped systematic errors commonly encountered in Structure-from-Motion (SfM) DEMs derived from UAV imagery.  
**Language:** MATLAB

| Script | Purpose |
| :--- | :--- |
| `fit_dome_effect_surface.m` | Fits a quadratic surface to sampled elevation points to model the dome effect. Excludes outlier tie points, computes RMSE against validation points, and exports a corrected DEM and diagnostic plots. |
| `profile_line.m` | Visualizes raw vs. corrected elevation profiles. Reads pairs of CSV files, generates multi-panel line plots, and exports high-resolution figures. |

* **Typical Inputs:** `sample.xls` (X, Y, Z points), `validation1.xls`, and a raw DEM (e.g., `Origin_DEM.tif`).
* **Outputs:** Corrected DEM, fitted dome surface (`Dome_Effect.tif`), and comparative profile figures.

### 2.2 `2_LIC_Generalization` – DEM Generalization with LIC
**Goal:** Smooth and generalize DEMs while preserving major topographic features using Line Integral Convolution (LIC). This reduces noise before Poisson fusion and produces visually pleasant hillshades.  
**Language:** MATLAB

| Script | Purpose |
| :--- | :--- |
| `run_LIC_hillshade_comparison.m` | Main driver script. Reads a DEM, applies LIC with varying kernel sizes, generates corresponding hillshades, and compares the results. |
| `line_integral_convolution.m` | Core implementation of LIC smoothing on a raster grid. |
| `generate_hillshade.m` | Helper function for computing single-azimuth hillshades. |

* **Outputs:** Smoothed DEMs (GeoTIFF), comparative hillshades, and effect-analysis figures.

### 2.3 `3_Reliefshading` – Poisson Hillshade Fusion
**Goal:** Fuse multiple hillshades from different illumination directions into a single shaded relief, capturing subtle micro-relief while preserving global structure via an iterative Poisson solver.  
**Language:** MATLAB

| Script | Purpose |
| :--- | :--- |
| `Poisson_hillshade.m` | End-to-end pipeline. Reads input hillshades (e.g., azimuths 300°, 45°), sanitizes, normalizes, performs two-stage Poisson fusion, and writes fused outputs. |
| `Poisson_edit.m` | Implements a Gauss–Seidel solver for the Poisson equation. |
| `sanitizeHillshade.m` & `minmaxNormalize.m` | Clean and normalize hillshade rasters prior to fusion. |
| `writeGeoTiffSafe.m` | Helper for writing GeoTIFFs robustly. |
| `FigurePlotTime.m` | Script for comparing runtime performance and parameter sensitivity (e.g., tolerance threshold). |

* **Inputs:** Hillshades computed at various azimuth angles (e.g., `H300.tif`, `H45.tif`). 
* **Outputs:** Fused hillshade GeoTIFF, preview PNG, and diagnostic figures.

### 2.4 `4_Mask_Classification` – Mask-Based Classification
**Goal:** Create simple binary or multi-class maps (e.g., snow/rock classification) from ratio or index rasters.  
**Language:** MATLAB

| Script | Purpose |
| :--- | :--- |
| `plot_IOR_classification.m` | Reads a ratio raster (e.g., Index of Ruggedness), displays the map and histogram, applies a threshold for binary masking, and exports a PNG. |

### 2.5 `5_ICESat_Optimization` – ICESat-2 Accuracy Assessment & Optimization
**Goal:** Assess and refine DEM elevations by comparing them with laser altimetry (ICESat-2 ATL06) and high-resolution reference DEMs (e.g., REMA).  
**Language:** Python (Jupyter Notebooks)

| File | Purpose |
| :--- | :--- |
| `optimization_utils.py` | Core functions for loading ICESat-2 HDF5/CSV files, CRS projection, sampling DEM values, computing error metrics, and detrending. |
| `ICESat_Accuracy_Optimization.ipynb` | Demonstrates how to select sample windows, compute statistics, and apply vertical bias correction using ICESat-2 data. |
| `REMA_DEM_Check.ipynb` | Compares your DEM with the REMA DEM, including slope-dependent error analysis. |

* **Outputs:** Summary tables of errors (mean bias, RMSE, STD), elevation difference plots along tracks, and bias-corrected DEMs.

### 2.6 `6_ReliefAnalysis` – Relief Analysis and Evaluation
**Goal:** Analyze the shaded relief and derived surfaces to support interpretation and quantify improvements.  
**Language:** Python (Jupyter Notebooks)

This module is subdivided into three steps:
1. **`1_Data_Preprocessing` (`1_data_preprocessing.ipynb`):** Clips hillshade and derivative rasters to specific regions (ridge, valley, IceDoline, TotalArea) using shared shapefiles, ensuring subsequent analyses operate on like-for-like extents.
2. **`2_KDE_Analysis` (`2_kde_analysis.ipynb`):** Computes descriptive statistics and Kernel Density Estimates (KDE). Produces violin plots, KDE curves, and boxplots to visualize the distribution of shading values.
3. **`3_Relief_Evaluation` (`3_relief_evaluation.ipynb`):** Computes relief metrics (slope, local relief), performs scatter/correlation analyses to quantify texture/contrast improvements, and evaluates terrain variability preservation.
* **Shared Data:** Requires shapefiles located in `shared_data/shp/` (e.g., `TotalArea.shp`, `ridgeArea.shp`).

---

## 💻 3. Environment Requirements

### MATLAB (Modules 1–4)
* **Version:** R2022a or newer recommended.
* **Required Toolboxes:**
  * Image Processing Toolbox
  * Mapping Toolbox
  * Curve Fitting Toolbox (Required for `fit_dome_effect_surface.m`)
* **Optional:** `export_fig` (For high-quality figure export. Scripts fall back to `exportgraphics` if missing).

### Python (Modules 5–6)
* **Version:** Python 3.9 or later.
* **Required Packages:** `geopandas`, `rasterio`, `h5py`, `numpy`, `pandas`, `shapely`, `matplotlib`, `seaborn`, `jupyterlab`.

**Installation Example (Conda):**
```bash
conda create -n reliefenv python=3.10 geopandas rasterio h5py numpy pandas matplotlib seaborn shapely jupyterlab -c conda-forge
conda activate reliefenv
```
*(Note: ICESat-2 ATL06 datasets are not included and must be acquired separately).*

---


## ⚠️ 4. Troubleshooting

* **File not found / Missing data:** Due to repository size constraints, original large DEMs and hillshades are not included. You must substitute the placeholder paths (e.g., `sampleFile`, `originDemFile`) with your own datasets.
* **MATLAB function undefined:** Ensure the Image Processing, Mapping, and Curve Fitting toolboxes are installed. Functions like `geotiffwrite` require the Mapping Toolbox.
* **Slow convergence in Poisson fusion:** Start with a larger tolerance in `Poisson_edit.m` for a coarse result. Decrease the tolerance gradually for final production. Ensure input rasters are normalized to [0,1].
* **Python import errors:** Ensure your conda environment is activated. Install `rasterio` and `geopandas` from the same channel (e.g., `conda-forge`) to avoid dependency conflicts.
* **Shapefile CRS mismatch:** When clipping rasters in Module 6, the shapefiles and rasters must share the same Coordinate Reference System (CRS). Use `rasterio.warp` or `geopandas.to_crs()` to re-project if necessary.

---

## 🙏 5. Citation and Acknowledgements

If this repository helps your research or project, please cite the associated paper as well as this repository. When reporting results, specify key parameter settings (e.g., LIC kernel length, azimuth angles, Poisson solver tolerance).

This workflow draws inspiration from relief-shading literature, including **Geisthövel & Hurni (2018)** for gradient-domain blending. We also thank reviewers for suggesting tie-point cleaning, ICESat-2 validation, and comprehensive relief analysis.

## 📄 6. License

This project is distributed under the terms of the MIT License. See the [LICENSE](LICENSE) file for details.
