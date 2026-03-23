from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import geopandas as gpd
import h5py
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import rasterio
from matplotlib.figure import Figure
from rasterio.crs import CRS
from rasterio.mask import mask
from shapely.geometry import box

BEAM_ORDER = ("gt1l", "gt1r", "gt2l", "gt2r", "gt3l", "gt3r")
PROFILE_COLORS = {
    "ICESat-2": "#4C78A8",
    "Initial DEM": "#72B7B2",
    "Optimized DEM": "#E6A157",
    "Final DEM": "#B279A2",
}


@dataclass(frozen=True)
class DemConfig:
    label: str
    path: Path
    sample_column: str
    replace_value: float | None = None


@dataclass(frozen=True)
class DemMetadata:
    config: DemConfig
    crs: CRS
    nodata: float | None
    bounds: tuple[float, float, float, float]
    resolution: tuple[float, float]
    width: int
    height: int


@dataclass(frozen=True)
class ProfileColumn:
    label: str
    column: str


def get_strong_beams_from_h5(atl06_h5_path: str | Path) -> tuple[int, list[str]]:
    path = Path(atl06_h5_path)
    with h5py.File(path, "r") as h5_file:
        sc_orient = int(np.asarray(h5_file["orbit_info"]["sc_orient"][()]).squeeze())

    if sc_orient == 1:
        return sc_orient, ["gt1l", "gt2l", "gt3l"]
    if sc_orient == 0:
        return sc_orient, ["gt1r", "gt2r", "gt3r"]
    raise RuntimeError("ICESat-2 is in transition orientation (sc_orient=2).")


def load_atl06_csv(csv_path: str | Path) -> pd.DataFrame:
    path = Path(csv_path)
    if not path.exists():
        raise FileNotFoundError(f"ATL06 CSV not found: {path}")

    df = pd.read_csv(path)
    required_columns = {"beam", "latitude", "longitude", "h_li"}
    missing = required_columns.difference(df.columns)
    if missing:
        raise ValueError(f"ATL06 CSV missing required columns: {', '.join(sorted(missing))}")
    return df


def atl06_csv_to_geodataframe(df: pd.DataFrame, target_crs) -> gpd.GeoDataFrame:
    gdf = gpd.GeoDataFrame(
        df.copy(),
        geometry=gpd.points_from_xy(df["longitude"], df["latitude"]),
        crs="EPSG:4326",
    )
    projected = gdf.to_crs(target_crs)
    projected["x"] = projected.geometry.x
    projected["y"] = projected.geometry.y
    return projected


def load_area_of_interest(area_path: str | Path, target_crs=None) -> gpd.GeoDataFrame:
    path = Path(area_path)
    if not path.exists():
        raise FileNotFoundError(f"Area shapefile not found: {path}")

    area_gdf = gpd.read_file(path)
    if area_gdf.empty:
        raise ValueError(f"Area shapefile is empty: {path}")
    if area_gdf.crs is None:
        raise ValueError(f"Area shapefile has no CRS: {path}")
    if target_crs is not None:
        area_gdf = area_gdf.to_crs(target_crs)
    return area_gdf


def clip_points_to_area(points_gdf: gpd.GeoDataFrame, area_gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    if points_gdf.empty:
        return points_gdf.copy()

    area = area_gdf.copy()
    if points_gdf.crs is not None and area.crs is not None and points_gdf.crs != area.crs:
        area = area.to_crs(points_gdf.crs)

    area = area.loc[area.geometry.notna() & ~area.geometry.is_empty].copy()
    if area.empty:
        return points_gdf.iloc[0:0].copy()

    invalid_mask = ~area.geometry.is_valid
    if invalid_mask.any():
        area.loc[invalid_mask, "geometry"] = area.loc[invalid_mask, "geometry"].buffer(0)

    min_x, min_y, max_x, max_y = area.total_bounds
    bbox_geom = box(min_x, min_y, max_x, max_y)
    candidates = points_gdf.loc[points_gdf.geometry.intersects(bbox_geom)].copy()
    if candidates.empty:
        return candidates

    mask_geom = area.union_all() if hasattr(area, "union_all") else area.unary_union
    clipped = candidates.loc[candidates.geometry.intersects(mask_geom)].copy()
    if clipped.empty:
        return clipped

    clipped["x"] = clipped.geometry.x
    clipped["y"] = clipped.geometry.y
    clipped.reset_index(drop=True, inplace=True)
    return clipped


def read_dem_metadata(dem_config: DemConfig) -> DemMetadata:
    if not dem_config.path.exists():
        raise FileNotFoundError(f"{dem_config.label} not found: {dem_config.path}")

    with rasterio.open(dem_config.path) as src:
        if src.crs is None:
            raise ValueError(f"{dem_config.label} has no CRS: {dem_config.path}")
        return DemMetadata(
            config=dem_config,
            crs=src.crs,
            nodata=src.nodata,
            bounds=(src.bounds.left, src.bounds.bottom, src.bounds.right, src.bounds.top),
            resolution=src.res,
            width=src.width,
            height=src.height,
        )


def transform_points_for_sampling(points_gdf: gpd.GeoDataFrame, target_crs) -> list[tuple[float, float]]:
    transformed = points_gdf.to_crs(target_crs)
    return list(zip(transformed.geometry.x.to_numpy(), transformed.geometry.y.to_numpy()))


def _sanitize_dem_values(values: np.ndarray, nodata: float | None, replace_value: float | None) -> np.ndarray:
    cleaned = values.astype(float, copy=True)
    cleaned[~np.isfinite(cleaned)] = np.nan
    if nodata is not None and np.isfinite(nodata):
        cleaned[cleaned == nodata] = np.nan
    if replace_value is not None:
        cleaned[cleaned == replace_value] = np.nan
    return cleaned


def sample_dem_values(dem_config: DemConfig, coordinates: list[tuple[float, float]]) -> np.ndarray:
    with rasterio.open(dem_config.path) as src:
        samples = np.array([sample[0] for sample in src.sample(coordinates, indexes=1)], dtype=float)
        return _sanitize_dem_values(samples, src.nodata, dem_config.replace_value)


def clip_dem_and_save(dem_config: DemConfig, area_gdf: gpd.GeoDataFrame, output_dir: str | Path) -> dict[str, object]:
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    with rasterio.open(dem_config.path) as src:
        area_in_dem_crs = area_gdf.to_crs(src.crs)
        clipped_data, clipped_transform = mask(src, area_in_dem_crs.geometry, crop=True, filled=True)
        clipped_band = _sanitize_dem_values(clipped_data[0], src.nodata, dem_config.replace_value)
        output_array = np.where(np.isnan(clipped_band), -9999.0, clipped_band).astype("float32")
        output_path = output_dir / f"{dem_config.path.stem}_clipped.tif"

        profile = src.profile.copy()
        profile.update(
            height=output_array.shape[0],
            width=output_array.shape[1],
            transform=clipped_transform,
            dtype="float32",
            nodata=-9999.0,
            compress="lzw",
        )

        with rasterio.open(output_path, "w", **profile) as dst:
            dst.write(output_array, 1)

    return {
        "dataset": dem_config.label,
        "output_path": str(output_path),
        "shape": output_array.shape,
        "nan_count": int(np.isnan(clipped_band).sum()),
        "valid_count": int(np.isfinite(clipped_band).sum()),
    }


def build_profile_dataframe(points_df: pd.DataFrame) -> pd.DataFrame:
    if points_df.empty:
        result = points_df.copy()
        result["cumulative_distance_m"] = pd.Series(dtype=float)
        return result

    df = points_df.copy()
    if "beam" in df.columns:
        df["beam"] = pd.Categorical(df["beam"], categories=BEAM_ORDER, ordered=True)
        group_iterable = df.groupby("beam", observed=True, sort=False)
    else:
        group_iterable = [(None, df)]

    ordered_parts: list[pd.DataFrame] = []
    offset = 0.0

    for _, group_df in group_iterable:
        if group_df.empty:
            continue
        if "delta_time" in group_df.columns and not group_df["delta_time"].isna().all():
            sort_columns = ["delta_time"]
        elif "segment_id" in group_df.columns and not group_df["segment_id"].isna().all():
            sort_columns = ["segment_id"]
        else:
            sort_columns = ["y", "x"]

        sorted_group = group_df.sort_values(sort_columns).copy()
        coordinates = sorted_group[["x", "y"]].to_numpy(dtype=float)
        distances = np.sqrt(np.sum(np.diff(coordinates, axis=0) ** 2, axis=1))
        cumulative = np.concatenate(([0.0], np.cumsum(distances))) + offset
        sorted_group["cumulative_distance_m"] = cumulative
        ordered_parts.append(sorted_group)
        offset = float(cumulative[-1]) + 50.0

    return pd.concat(ordered_parts, ignore_index=True)


def create_profile_figure(profile_df: pd.DataFrame, profile_columns: list[ProfileColumn]) -> Figure:
    figure = Figure(figsize=(9, 5), tight_layout=True)
    axes = figure.add_subplot(111)

    if profile_df.empty:
        axes.set_xlabel("Distance along track (m)")
        axes.set_ylabel("Elevation (m)")
        axes.text(0.5, 0.5, "No profile data available.", ha="center", va="center")
        return figure

    for profile_column in profile_columns:
        valid = profile_df[["cumulative_distance_m", profile_column.column]].dropna()
        if valid.empty:
            continue
        axes.plot(
            valid["cumulative_distance_m"],
            valid[profile_column.column],
            marker="o",
            markersize=2.2,
            linewidth=1.2,
            label=profile_column.label,
            color=PROFILE_COLORS.get(profile_column.label),
        )

    axes.set_xlabel("Distance along track (m)")
    axes.set_ylabel("Elevation (m)")
    axes.grid(True, linestyle="--", linewidth=0.5, alpha=0.7)
    axes.legend(loc="best")
    return figure


def compute_metrics(reference_series: pd.Series, dem_series: pd.Series) -> dict[str, float]:
    valid_mask = reference_series.notna() & dem_series.notna()
    ref = reference_series.loc[valid_mask].astype(float)
    dem = dem_series.loc[valid_mask].astype(float)

    if ref.empty:
        return {"N": 0, "Bias": np.nan, "MAE": np.nan, "RMSE": np.nan, "STD": np.nan}

    errors = dem - ref
    return {
        "N": len(errors),
        "Bias": float(errors.mean()),
        "MAE": float(np.abs(errors).mean()),
        "RMSE": float(np.sqrt(np.mean(errors**2))),
        "STD": float(errors.std(ddof=1)) if len(errors) > 1 else 0.0,
    }


def read_raster_with_nan(raster_path: str | Path, replace_value: float | None = None) -> dict[str, object]:
    path = Path(raster_path)
    with rasterio.open(path) as src:
        raster = src.read(1).astype("float32")
        raster[raster == -99] = np.nan
        if src.nodata is not None and np.isfinite(src.nodata):
            raster[raster == src.nodata] = np.nan
        if replace_value is not None:
            raster[raster == replace_value] = np.nan
        raster[~np.isfinite(raster)] = np.nan

        return {
            "array": raster,
            "bounds": src.bounds,
            "crs": src.crs,
            "width": src.width,
            "height": src.height,
            "nodata": src.nodata,
            "extent": [src.bounds.left, src.bounds.right, src.bounds.bottom, src.bounds.top],
        }
