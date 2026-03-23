# 5_ICESat_Optimization

This folder is a standalone, GitHub-ready version of the ICESat-2 accuracy optimization workflows based on the original local notebooks:

- `ATL06_Desktop_App/NewProcess.ipynb` (source workflow)
- `REMA_DEM_Check.ipynb`

The original files were left unchanged. This folder contains optimized copies and the helper functions they need.

## Files

- `ICESat_Accuracy_Optimization.ipynb`
  Standalone ICESat-2 accuracy optimization workflow.
- `REMA_DEM_Check.ipynb`
  Standalone REMA-final DEM quick check workflow.
- `optimization_utils.py`
  Shared helper functions copied and simplified from the original project.
- `requirements.txt`
  Python dependencies for the notebooks.

## Setup

```bash
pip install -r requirements.txt
```

## Notebook 1: `ICESat_Accuracy_Optimization.ipynb`

This notebook does the following:

1. Read one ATL06 CSV and its matching ATL06 HDF5.
2. Detect the strong beams automatically from `sc_orient`.
3. Keep only strong ATL06 points.
4. Read 3 DEM datasets and one area shapefile.
5. Clip ATL06 and DEMs to the area.
6. Plot the clipped ATL06 track and mark the profile start point.
7. Sample DEM elevations at ATL06 point locations.
8. Build ICESat-2 / DEM comparison profiles and summary metrics.

Edit the path configuration cell first if your local paths are different.

## Notebook 2: `REMA_DEM_Check.ipynb`

This notebook does the following:

1. Read `REMA_DEM.tif`.
2. Convert `-99` to `NaN`.
3. Compute summary statistics.
4. Plot a 1x2 figure:
   - spatial map
   - histogram with guide lines

Edit the DEM path cell first if your local path is different.

## Notes

- The notebooks are self-contained apart from `optimization_utils.py`.
- The hard-coded paths were preserved from the working local workflow for convenience.
- For public GitHub use, you can replace the path cell values with your own local paths.
