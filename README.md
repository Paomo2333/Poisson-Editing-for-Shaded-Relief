# Poisson-Editing-for-Shaded-Relief

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
This repository implements and documents a Poisson-editing-based shaded-relief workflow for topographic enhancement, especially in low-to-moderate relief terrain (e.g., glacier geomorphology mapping scenarios). It provides MATLAB scripts that cover DEM preprocessing, hillshade generalization/fusion, and downstream classification visualization.

## 1. Project Goal

> **Official repository for the paper:** > *"Enhancing Glacier Geomorphology Mapping Using Relief Shading: A Case Study of the Larsemann Hills, East Antarctica"*
The core workflow is:
1. Generate (or load) hillshades from multiple illumination azimuths.
2. Fuse complementary terrain cues via iterative Poisson editing.
3. Export enhanced rasters and figures for geomorphological interpretation.

## 📖 Overview
This repository provides a simple, highly portable, and effective **relief shading method** based on Poisson editing. It is specifically designed to enhance topographic visualization for geomorphological mapping in areas with low to moderate terrain relief. 
The repository is organized into four modules that can be run independently or chained together.

Our approach improves upon traditional methods by integrating and editing hillshades from multiple illumination directions. 
---

## 2. Repository Structure

```text
Poisson-Editing-for-Shaded-Relief/
├── README.md
└── Reliefshading_Github/
    ├── 1_Dome_profile/
    ├── 2_LIC_Generalization/
    ├── 3_Reliefshading/
    └── 4_Mask_Classification/
```

### 2.1 `1_Dome_profile` (Profile and dome-effect analysis)
- `profile_line.m`: Loads five profile CSV pairs (raw vs processed), creates panel plots, and exports high-resolution figures.
- `fit_dome_effect_surface.m`: Surface fitting for dome-effect error analysis.
- Example data:
  - `ErrorLine/Line1.csv ... Line5.csv`
  - `No_errorLine/No_line1.csv ... No_line5.csv`
  - `sample.xls`, `validation1.xls`

### 2.2 `2_LIC_Generalization` (DEM generalization with LIC)
- `run_LIC_hillshade_comparison.m`:
  - Runs line integral convolution (LIC) on DEM data.
  - Generates hillshades for different LIC lengths and compares them.
  - Exports LIC-processed DEM rasters.
- `line_integral_convolution.m`: LIC core algorithm.
- `generate_hillshade.m`: Hillshade generation helper.

> Note: This module assumes DEM input under `projectRoot/data/DEM_Data` by default. Adjust path variables in the script if your local data layout is different.

### 2.3 `3_Reliefshading` (Core Poisson fusion module)
- `Poisson_hillshade.m`: Main pipeline script.
  - Reads hillshades from multiple azimuths (e.g., `LIC15_300_45_2_1m.tif`).
  - Performs two-stage Poisson fusion.
  - Exports GeoTIFF outputs and a preview figure.
- `Possion_edit.m`: Iterative Poisson solver (Gauss-Seidel style implementation).
- `sanitizeHillshade.m` / `minmaxNormalize.m`: Hillshade sanitization and normalization.
- `writeGeoTiffSafe.m`: Safer GeoTIFF export utility.
- `FigurePlotTime.m`: Runtime and sensitivity plotting.

**Acknowledgements**: This work was inspired by and builds upon the suggestions from [Geisthövel, R., & Hurni, L. (2018)](#acknowledgements).
> Note: `Poisson_hillshade.m` uses specific input-file naming and directory assumptions. Verify these before execution.

### 2.4 `4_Mask_Classification` (Mask-based classification and plotting)
- `plot_IOR_classification.m`:
  - Loads IOR raster.
  - Produces a 3-panel figure (spatial map, histogram, binary classification).
  - Exports a high-resolution PNG.
- Example output: `figures/IOR_classification_3panel.png`

---

## ⚙️ Repository Structure & Modules
## 3. Environment Requirements

Recommended environment:
- MATLAB R2022a or newer.

The pipeline is divided into four main processing modules:
Common dependencies/toolboxes:
- Image Processing Toolbox (image operations and masking workflows).
- Mapping Toolbox (`readgeoraster`, `geotiffwrite`, geospatial raster I/O).
- Optional: `export_fig` (some scripts prefer it for publication-quality exports).

---

### 1. UAV DEM Optimization (`1-Dome_profile`)
Focuses on assessing and optimizing the quality of UAV-derived Digital Elevation Models (DEMs).
* `profile_line`: Fits Dome errors and performs profile validation.
## 4. Quick Start

### 2. LIC Generalization (`2-LIC_Generalization`)
Performs DEM generalization using the Line Integral Convolution (LIC) method.
* `run_LIC_hillshade_comparison`: Generates and compares hillshades using the LIC method.
In MATLAB, from the repository root, run module scripts as needed:

### 3. Relief Shading (`3-Reliefshading`)
The core module for performing Poisson editing to fuse multi-directional hillshades.
* `Poisson_hillshade`: Main executable script for the Poisson editing workflow.
* `Poisson_edit`: Core algorithmic implementation of the Poisson edit.
* `sanitizeHillshade`: Preprocesses and normalizes raw hillshade data.
* `minmaxNormalize`: Applies Min-Max normalization to the generated shaded relief.
* `FigurePlotTime`: Conducts sensitivity analysis and runtime evaluation for the Poisson editing process.
* `writeGeoTiffSafe`: Safely exports the processed data to GeoTiff format.
* `exportPng`: Exports visualization results as PNG images.
```matlab
% 1) Profile comparison plots
cd('Reliefshading_Github/1_Dome_profile');
profile_line

### 4. Mask Classification (`4-Mask_Classification`)
Classifies geomorphological features using masking techniques.
* `plot_IOR_classification`: Performs mask classification specifically for snow and bare rock areas.
% 2) LIC generalization and hillshade comparison
cd('../2_LIC_Generalization');
run_LIC_hillshade_comparison

% 3) Poisson fusion
cd('../3_Reliefshading');
Poisson_hillshade

% 4) IOR classification figure
cd('../4_Mask_Classification');
plot_IOR_classification
```

---
## 💻 Prerequisites

This project is developed and tested in **MATLAB** *(e.g., R2022a or later)*. 
To run the scripts successfully, please ensure you have the following MATLAB Toolboxes installed:
* **Image Processing Toolbox** *(Required for masking and general image operations)*
* **Mapping Toolbox** *(Required for GeoTiff I/O and spatial data handling)*
* **Export_fig** *(Essential for exporting high-quality, publication-ready figures without background margins.
*(Ensure this library is downloaded and added to your MATLAB path.)*

## 5. Input/Output Organization Tips

Because path assumptions differ slightly across scripts, the following practices help:
- Keep input data close to scripts when possible and use relative paths.
- If using centralized data folders (e.g., `data/`), define `projectRoot` and `dataDir` explicitly at the top of each script.
- Create output folders in advance (e.g., `figures/`, `output/`, `Poisson_results/`) or ensure scripts auto-create them.

---

## 6. Troubleshooting

1. **Missing `.tif` or `.csv` files**
   Check `fullfile(...)` path construction and local folder layout.

2. **`geotiffwrite` / `readgeoraster` unavailable**
   Usually indicates Mapping Toolbox is not installed.

3. **`export_fig` unavailable**
   Core workflow is still runnable; switch to `exportgraphics` fallback where applicable.

4. **Slow Poisson fusion runtime**
   Increase tolerance (`tol`) for quick validation first, then rerun with stricter settings.

---

## 7. Citation and Usage Notes

If this repository helps your research, please report:
- Use of multi-azimuth hillshade fusion with Poisson editing.
- Key parameter settings for your dataset (e.g., azimuth/elevation angles, `tol`).

If desired, this codebase can be further packaged into a one-click reproducible entry point (e.g., `main.m` + `config.m`) with unified path checking and parameter management.
