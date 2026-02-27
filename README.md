# Poisson-Editing-for-Shaded-Relief

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


> **Official repository for the paper:** > *"Enhancing Glacier Geomorphology Mapping Using Relief Shading: A Case Study of the Larsemann Hills, East Antarctica"*

## 📖 Overview
This repository provides a simple, highly portable, and effective **relief shading method** based on Poisson editing. It is specifically designed to enhance topographic visualization for geomorphological mapping in areas with low to moderate terrain relief. 

Our approach improves upon traditional methods by integrating and editing hillshades from multiple illumination directions. 

**Acknowledgements**: This work was inspired by and builds upon the suggestions from [Geisthövel, R., & Hurni, L. (2018)](#acknowledgements).

---

## ⚙️ Repository Structure & Modules

The pipeline is divided into four main processing modules:

### 1. UAV DEM Optimization (`1-Dome_profile`)
Focuses on assessing and optimizing the quality of UAV-derived Digital Elevation Models (DEMs).
* `profile_line`: Fits Dome errors and performs profile validation.

### 2. LIC Generalization (`2-LIC_Generalization`)
Performs DEM generalization using the Line Integral Convolution (LIC) method.
* `run_LIC_hillshade_comparison`: Generates and compares hillshades using the LIC method.

### 3. Relief Shading (`3-Reliefshading`)
The core module for performing Poisson editing to fuse multi-directional hillshades.
* `Poisson_hillshade`: Main executable script for the Poisson editing workflow.
* `Poisson_edit`: Core algorithmic implementation of the Poisson edit.
* `sanitizeHillshade`: Preprocesses and normalizes raw hillshade data.
* `minmaxNormalize`: Applies Min-Max normalization to the generated shaded relief.
* `FigurePlotTime`: Conducts sensitivity analysis and runtime evaluation for the Poisson editing process.
* `writeGeoTiffSafe`: Safely exports the processed data to GeoTiff format.
* `exportPng`: Exports visualization results as PNG images.

### 4. Mask Classification (`4-Mask_Classification`)
Classifies geomorphological features using masking techniques.
* `plot_IOR_classification`: Performs mask classification specifically for snow and bare rock areas.

---
## 💻 Prerequisites

This project is developed and tested in **MATLAB** *(e.g., R2022a or later)*. 
To run the scripts successfully, please ensure you have the following MATLAB Toolboxes installed:
* **Image Processing Toolbox** *(Required for masking and general image operations)*
* **Mapping Toolbox** *(Required for GeoTiff I/O and spatial data handling)*
* **Export_fig** *(Essential for exporting high-quality, publication-ready figures without background margins.
*(Ensure this library is downloaded and added to your MATLAB path.)*
