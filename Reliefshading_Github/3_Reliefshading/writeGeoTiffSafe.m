function writeGeoTiffSafe(fname, A, R, epsg)
%WRITEGEOTIFFSAFE Write GeoTIFF with EPSG fallback protection
%
%   writeGeoTiffSafe(fname, A, R, epsg)
%
%   Attempts to write with CoordRefSysCode first.
%   If it fails (older MATLAB versions), falls back to
%   writing without CRS metadata.

    try
        geotiffwrite(fname, A, R, 'CoordRefSysCode', epsg);
    catch ME
        warning('GeoTIFF write with EPSG failed. Writing without CRS.');
        warning(ME.message);
        geotiffwrite(fname, A, R);
    end

end