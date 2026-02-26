%% ========================================================================
%  run_LIC_hillshade_comparison.m
%
%  Perform Line Integral Convolution (LIC) on DEM,
%  generate hillshades under different LIC lengths,
%  and export processed DEMs and visualization figures.
%
%  Project structure (recommended):
%
%  ProjectRoot/
%  │
%  ├── data/DEM_Data/New_DEM20251105.tif
%  ├── src/run_LIC_hillshade_comparison.m
%  ├── output/LIC_DEM/
%  └── figures/
%
%  Author: Yibo Li
%  ========================================================================

clc; clear; close all;

%% ========================== 1. PATH SETUP ===============================

% Get script location robustly
thisFile = which(mfilename);
if isempty(thisFile)
    error('Script must be saved before running.');
end

scriptDir   = fileparts(thisFile);
projectRoot = fileparts(scriptDir);

dataDir     = fullfile(projectRoot, "data", "DEM_Data");
outputDEM   = fullfile(projectRoot, "output", "LIC_DEM");
figDir      = fullfile(projectRoot, "figures");

% Create output folders if necessary
if ~isfolder(outputDEM); mkdir(outputDEM); end
if ~isfolder(figDir); mkdir(figDir); end

demFile = fullfile(dataDir, "New_DEM20251105.tif");

if ~isfile(demFile)
    error("DEM file not found: %s", demFile);
end

%% ========================== 2. READ DEM ================================

[z, R] = readgeoraster(demFile);
z = double(z);

% Replace invalid values
z(z == -99) = NaN;

% Ensure single band
if ndims(z) == 3
    z = z(:,:,1);
end

if ndims(z) ~= 2
    error("DEM must be a 2D matrix.");
end

[X,Y] = worldGrid(R);

%% ========================== 3. SLOPE VECTOR FIELD ======================

[dzdy, dzdx] = gradient(z, R.CellExtentInWorldX, R.CellExtentInWorldY);

magnitude = sqrt(dzdx.^2 + dzdy.^2) + eps;

Vx = dzdx ./ magnitude;
Vy = dzdy ./ magnitude;

%% ========================== 4. LIC PROCESSING ==========================

LIC_lengths = 10:5:45;
ds = 1;

zLIC = cell(numel(LIC_lengths),1);

for i = 1:numel(LIC_lengths)
    L = LIC_lengths(i);
    fprintf("Processing LIC length = %d...\n", L);
    zLIC{i} = line_integral_convolution(z, Vx, Vy, L, ds);
end

%% ========================== 5. HILLSHADE ===============================

azimuth    = 315;
elevation  = 45;
vert_exag  = 2;

dx = R.CellExtentInWorldX;
dy = R.CellExtentInWorldY;

hs = cell(size(zLIC));

for i = 1:numel(zLIC)
    temp = zLIC{i};
    temp(isnan(temp)) = 0;
    hs{i} = generate_hillshade(temp * (dx/dy), azimuth, elevation, vert_exag);
end

%% ========================== 6. VISUALIZATION ===========================

x = X(1,:);
y = Y(:,1);

fig = figure('Color','w','Units','centimeters','Position',[3 3 16 12]);
t = tiledlayout(2,2,'TileSpacing','tight','Padding','compact');

display_idx = [3 5 7 9]; % show selected LIC lengths

for k = 1:4
    nexttile
    imagesc(x,y,hs{display_idx(k)});
    axis xy equal
    colormap(gray(256))
    colorbar('southoutside','FontSize',8)
    
    title(sprintf("LIC Length: %d", LIC_lengths(display_idx(k))),...
        'FontSize',10,'FontWeight','normal');
    
    xlabel('X Coordinate','FontSize',9);
    ylabel('Y Coordinate','FontSize',9);
    
    set(gca,'FontSize',8,'TickDir','out');
end

exportgraphics(fig, fullfile(figDir,"Hillshade_Comparison.png"),...
    'Resolution',600);

%% ========================== 7. EXPORT DEM ==============================

coordRefSysCode = 32743;

for i = 1:numel(LIC_lengths)
    outName = sprintf("DEM_LIC_%d.tif", LIC_lengths(i));
    geotiffwrite(fullfile(outputDEM,outName),...
        zLIC{i}, R, "CoordRefSysCode", coordRefSysCode);
end

disp("All LIC DEMs exported successfully.");