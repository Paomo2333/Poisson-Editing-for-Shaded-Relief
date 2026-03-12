%% fit_dome_effect_surface.m
% -------------------------------------------------------------------------
% Fit a quadratic dome-effect surface from sampled elevation points,
% validate the fitted model, visualize fitting diagnostics, and export
% the fitted dome-effect raster as a GeoTIFF.
%
% Author      : Li Yibo
% Affiliation : Sun Yat-sen University
% Date        : 2025-10-25
%
% Requirements:
%   - MATLAB
%   - Curve Fitting Toolbox
%   - Mapping Toolbox
%   - export_fig (optional, recommended for transparent PNG export)
%
% Expected folder structure (relative to this script):
%   .
%   ├─ fit_dome_effect_surface.m
%   ├─ data/
%   │   ├─ sample.xls
%   │   └─ validation1.xls
%   ├─ Origin_DEM/
%   │   └─ Origin_DEM.tif
%   └─ outputs/
%       ├─ figures/
%       └─ rasters/
%
% Inputs:
%   - sample.xls       : training/sample points
%                        column 2 = X / lon
%                        column 3 = Y / lat
%                        column 5 = elevation
%   - validation1.xls  : validation points
%                        column 1 = X / lon
%                        column 2 = Y / lat
%                        column 3 = elevation
%   - Origin_DEM.tif   : original DEM used to build full-domain surface
%
% Outputs:
%   - outputs/figures/Fig_DomeEffect.png
%   - outputs/rasters/Dome_Effect.tif
%
% Notes:
%   - This script assumes projected coordinates (e.g., UTM), although the
%     source variable names are retained as lon / lat for compatibility
%     with the original workflow.
%   - Normalization is enabled during fitting to reduce numerical issues
%     caused by large projected coordinate values.
% -------------------------------------------------------------------------

clc;
clear;
close all;

%% ============================ Path settings =============================
thisFile = mfilename('fullpath');
if isempty(thisFile)
    baseDir = pwd;
else
    baseDir = fileparts(thisFile);
end

dataDir      = fullfile(baseDir, 'data');
demDir       = fullfile(baseDir, 'Origin_DEM');
figOutDir    = fullfile(baseDir, 'outputs', 'figures');
rasterOutDir = fullfile(baseDir, 'outputs', 'rasters');

if ~exist(figOutDir, 'dir');    mkdir(figOutDir);    end
if ~exist(rasterOutDir, 'dir'); mkdir(rasterOutDir); end

sampleFile     = fullfile(dataDir, 'sample.xls');
validationFile = fullfile(dataDir, 'validation1.xls');
originDemFile  = fullfile(demDir, 'Origin_DEM.tif');

%% ========================== User parameters ============================
excludedIndices = [72, 93, 102, 103];  % manually excluded sample points
fitTypeName     = 'poly22';            % quadratic surface
nodataValue     = -99;                 % NoData value in original DEM
epsgCode        = 32743;               % WGS 84 / UTM zone 43S

figName         = 'Fig_DomeEffect.png';
rasterName      = 'Dome_Effect.tif';

%% ========================== Input validation ===========================
assert(exist(sampleFile, 'file') == 2, ...
    'Sample file not found: %s', sampleFile);
assert(exist(validationFile, 'file') == 2, ...
    'Validation file not found: %s', validationFile);
assert(exist(originDemFile, 'file') == 2, ...
    'Original DEM file not found: %s', originDemFile);

%% ========================== Read input tables ==========================
% Training/sample data
sampleTbl = readtable(sampleFile);
xSample   = sampleTbl{:, 2};
ySample   = sampleTbl{:, 3};
zSample   = sampleTbl{:, 5};

% Validation data
valTbl = readtable(validationFile);
xVal   = valTbl{:, 1};
yVal   = valTbl{:, 2};
zVal   = valTbl{:, 3};

%% =========================== Surface fitting ===========================
[xData, yData, zData] = prepareSurfaceData(xSample, ySample, zSample);

% Define fitting model
ft = fittype(fitTypeName);

% Exclude manually identified outliers
excludedPoints = excludedata(xData, yData, 'Indices', excludedIndices);

% Fit options
opts = fitoptions('Method', 'LinearLeastSquares');
opts.Normalize = 'on';
opts.Exclude   = excludedPoints;

% Fit the model
[fitResult, gof] = fit([xData, yData], zData, ft, opts);

%% ========================== Validation metrics =========================
[xValidation, yValidation, zValidation] = prepareSurfaceData(xVal, yVal, zVal);
zPred = fitResult(xValidation, yValidation);

residual = zValidation - zPred;
nOutside = nnz(isnan(residual));

validMask = ~isnan(residual);
residual  = residual(validMask);
zValidUse = zValidation(validMask);
zPredUse  = zPred(validMask);

sse  = sum(residual .^ 2);
rmse = sqrt(mean(residual .^ 2));

% Validation R^2
sst = sum((zValidUse - mean(zValidUse)) .^ 2);
if sst > 0
    r2Val = 1 - sse / sst;
else
    r2Val = NaN;
end

fprintf('Validation statistics for dome-effect fitting:\n');
fprintf('    SSE  : %.6f\n', sse);
fprintf('    RMSE : %.6f\n', rmse);
fprintf('    R^2  : %.6f\n', r2Val);
fprintf('    %d point(s) fall outside the fitted data domain.\n', nOutside);

%% ============================= Figure export ===========================
figPath = fullfile(figOutDir, figName);

% Figure canvas (A4-friendly layout)
fig = figure('Units', 'centimeters', ...
             'Position', [2, 2, 31.3, 20.6], ...
             'Color', 'w');

set(fig, 'PaperUnits', 'centimeters', ...
         'PaperSize', [21, 29.7], ...
         'PaperPosition', [1.7, 1.7, 17.6, 12]);

xRange = [min([xData; xValidation]), max([xData; xValidation])];
yRange = [min([yData; yValidation]), max([yData; yValidation])];

tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% -------------------- (A) Contour plot --------------------
ax1 = nexttile(tl, 1, [2 1]);
hCnt = plot(fitResult, [xData, yData], zData, ...
    'Style', 'Contour', ...
    'Exclude', excludedPoints, ...
    'XLim', xRange, ...
    'YLim', yRange);

hold(ax1, 'on');
hVal = plot(xValidation, yValidation, 'bo', ...
    'MarkerFaceColor', 'w', ...
    'LineWidth', 1, ...
    'MarkerSize', 6);

cb = colorbar(ax1);
cb.Label.String = 'Elevation (m)';
cb.Label.FontSize = 14;
cb.Label.FontWeight = 'bold';

ax1.XAxis.TickLabelFormat = '%.2f';
ax1.YAxis.TickLabelFormat = '%.4f';
ax1.FontSize = 12;
ax1.FontName = 'Arial';

xlabel(ax1, 'X (m)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel(ax1, 'Y (m)', 'FontSize', 14, 'FontWeight', 'bold');
grid(ax1, 'on');

% Legend handle order
if numel(hCnt) >= 3
    hContour   = hCnt(1);
    hSamplePts = hCnt(2);
    hExcluded  = hCnt(3);

    legend(ax1, [hContour, hSamplePts, hExcluded, hVal], ...
        {'Dome-effect surface', 'Sample points', 'Excluded points', 'Validation points'}, ...
        'Location', 'southeast', ...
        'Interpreter', 'none', ...
        'FontSize', 12, ...
        'FontWeight', 'bold');
end

% Annotation
textX = xRange(1) + 0.08 * diff(xRange);
textY = yRange(1) + 0.10 * diff(yRange);
txt = sprintf('RMSE: %.3f\nR^2: %.3f', rmse, r2Val);
text(ax1, textX, textY, txt, ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [1 1 1], ...
    'Margin', 5);

hold(ax1, 'off');

% -------------------- (B) Fitted surface --------------------
ax2 = nexttile(tl, 2);
hSurf = plot(fitResult, [xData, yData], zData, ...
    'Exclude', excludedPoints, ...
    'XLim', xRange, ...
    'YLim', yRange);

ax2.XAxis.TickLabelFormat = '%.2f';
ax2.YAxis.TickLabelFormat = '%.4f';
ax2.FontSize = 11;
ax2.FontName = 'Arial';

xlabel(ax2, 'X (m)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(ax2, 'Y (m)', 'FontSize', 13, 'FontWeight', 'bold');
zlabel(ax2, 'Elevation (m)', 'FontSize', 13, 'FontWeight', 'bold');
grid(ax2, 'on');
view(ax2, -39, 30);

if numel(hSurf) >= 3
    legend(ax2, hSurf, ...
        {'Dome-effect surface', 'Sample points', 'Excluded points'}, ...
        'Location', 'northeast', ...
        'Interpreter', 'none', ...
        'FontSize', 11, ...
        'FontWeight', 'bold');
end

% -------------------- (C) Residual plot --------------------
ax3 = nexttile(tl, 4);
hRes = plot(fitResult, [xData, yData], zData, ...
    'Style', 'Residual', ...
    'Exclude', excludedPoints, ...
    'XLim', xRange, ...
    'YLim', yRange);

if numel(hRes) >= 2
    set(hRes(2), 'MarkerEdgeColor', 'r', ...
                 'LineWidth', 1, ...
                 'MarkerSize', 10);
end

ax3.XAxis.TickLabelFormat = '%.2f';
ax3.YAxis.TickLabelFormat = '%.4f';
ax3.FontSize = 11;
ax3.FontName = 'Arial';

xlabel(ax3, 'X (m)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(ax3, 'Y (m)', 'FontSize', 13, 'FontWeight', 'bold');
zlabel(ax3, 'Residual (m)', 'FontSize', 13, 'FontWeight', 'bold');
grid(ax3, 'on');
view(ax3, -39, 30);

if numel(hRes) >= 2
    legend(ax3, hRes, ...
        {'Sample points', 'Excluded points'}, ...
        'Location', 'northeast', ...
        'Interpreter', 'none', ...
        'FontSize', 11, ...
        'FontWeight', 'bold');
end

% Export figure
set(fig, 'Color', 'none');
set(findall(fig, 'type', 'axes'), 'Color', 'none');
set(fig, 'InvertHardcopy', 'off');

if exist('export_fig', 'file') == 2
    export_fig(figPath, '-png', '-r600', '-transparent', '-nocrop');
else
    warning(['export_fig not found. Falling back to exportgraphics. ', ...
             'Transparent background may depend on MATLAB version.']);
    exportgraphics(fig, figPath, 'Resolution', 600, 'BackgroundColor', 'none');
end

fprintf('Figure exported to:\n    %s\n', figPath);

%% ====================== Build full-domain surface ======================
[originDEM, R] = readgeoraster(originDemFile);
originDEM = double(originDEM);
originDEM(originDEM == nodataValue) = NaN;

[numRows, numCols] = size(originDEM);

% Build raster grid in map coordinates
[X, Y] = meshgrid( ...
    linspace(R.XWorldLimits(1), R.XWorldLimits(2), numCols), ...
    linspace(R.YWorldLimits(2), R.YWorldLimits(1), numRows));

% Evaluate fitted surface across full DEM extent
domeEffect = fitResult(X, Y);

% Preserve original NoData mask
domeEffect(isnan(originDEM)) = NaN;

%% ======================== Quick visualization ==========================
figure('Color', 'w');
imagesc(domeEffect);
axis image;
hold on;
contour(domeEffect, 'LineColor', 'k');
hold off;
colorbar;
title('Dome-effect surface with contours', 'FontWeight', 'bold');

%% =========================== GeoTIFF export ============================
rasterPath = fullfile(rasterOutDir, rasterName);

geotiffwrite(rasterPath, domeEffect, R, 'CoordRefSysCode', epsgCode);

fprintf('GeoTIFF exported to:\n    %s\n', rasterPath);

%% ============================= End message =============================
fprintf('\nWorkflow completed successfully.\n');
fprintf('Training R^2 (fit object)    : %.6f\n', gof.rsquare);
fprintf('Validation R^2               : %.6f\n', r2Val);
fprintf('Validation RMSE              : %.6f m\n', rmse);