%% profile_line.m
% Plot 5 profile lines (original vs processed) from CSV files in two folders.
% Output: high-resolution PNG (transparent if possible).
%
% Expected file pattern:
%   origFolder/Line1.csv ... Line5.csv
%   procFolder/No_line1.csv ... No_line5.csv
%
% CSV columns:
%   - Column 2: distance
%   - Column 3: elevation
%
% Author: <Yibo Li / Sun yat-sen University>
% -------------------------------------------------------------------------

clc; clear; close all;

%% ===================== User settings =====================
thisFile = mfilename('fullpath');
if isempty(thisFile)
    baseDir = pwd;
else
    baseDir = fileparts(thisFile);
end

origFolder = fullfile(baseDir, "ErrorLine");
procFolder = fullfile(baseDir, "No_errorLine");   

nLines       = 5;

% File name patterns
origPattern  = "Line%d.csv";
procPattern  = "No_line%d.csv";

% CSV columns (1-based)
colDist      = 2;
colElev      = 3;

% Clip negative elevations to 0 (set [] to disable)
clipMinElev  = 0;

% Per-panel y-limits (orig and processed), size must be [nLines x 2]
% If you want auto limits, set empty: ylimsOrig = []; ylimsProc = [];
ylimsOrig = [ ...
     0  75; ...
     0  30; ...
     0  85; ...
     0 150; ...
     0  80  ...
];
ylimsProc = [ ...
    -5  65; ...
    -3  20; ...
   -10  70; ...
   -10 120; ...
   -10  70  ...
];

% Figure layout (cm)
figPosCM     = [22.75, 6.32, 24.21, 19.69];  % [x y w h] in centimeters

% Style
fontName     = "Arial";
fontSize     = 12;
gridColor    = [0.5 0.5 0.5];
gridStyle    = "--";
lineWidth    = 0.8;

% Area fill style
origFillColor = [1 0 0];  % red
procFillColor = [0 0 1];  % blue
fillAlpha     = 0.6;

% Export
outFile       = "profile_lines.png";
dpi           = 600;
useExportFig  = true;  % if export_fig exists; auto fallback otherwise
transparentBG = true;

%% ===================== Load data =====================
[origDist, origElev] = readProfiles(origFolder, origPattern, nLines, colDist, colElev);
[procDist, procElev] = readProfiles(procFolder, procPattern, nLines, colDist, colElev);

%% ===================== Plot =====================
fig = figure('Units','centimeters', 'Position', figPosCM, 'Color','w');
tiledlayout(nLines, 2, 'TileSpacing','compact', 'Padding','compact');

for i = 1:nLines
    % ---- Original (left column)
    nexttile((i-1)*2 + 1);
    plotOneProfile(origDist{i}, origElev{i}, clipMinElev, origFillColor, fillAlpha, ...
                   lineWidth, fontName, fontSize, gridStyle, gridColor);
    if ~isempty(ylimsOrig)
        ylim(ylimsOrig(i,:));
    end

    % ---- Processed (right column)
    nexttile((i-1)*2 + 2);
    plotOneProfile(procDist{i}, procElev{i}, clipMinElev, procFillColor, fillAlpha, ...
                   lineWidth, fontName, fontSize, gridStyle, gridColor);
    if ~isempty(ylimsProc)
        ylim(ylimsProc(i,:));
    end
end

% Apply global typography (axes + text)
ax = findall(fig, 'Type','axes');
set(ax, 'FontName', fontName, 'FontSize', fontSize);
set(findall(fig,'Type','text'), 'FontName', fontName, 'FontSize', fontSize);

%% ===================== Export =====================
exportFigure(fig, outFile, dpi, useExportFig, transparentBG);

fprintf("Done. Saved: %s\n", outFile);

%% ===================== Local functions =====================
function [distCell, elevCell] = readProfiles(folder, pattern, nLines, colDist, colElev)
    arguments
        folder (1,1) string
        pattern (1,1) string
        nLines (1,1) double {mustBeInteger, mustBePositive}
        colDist (1,1) double {mustBeInteger, mustBePositive}
        colElev (1,1) double {mustBeInteger, mustBePositive}
    end

    if ~isfolder(folder)
        error("Folder not found: %s", folder);
    end

    distCell = cell(nLines,1);
    elevCell = cell(nLines,1);

    for i = 1:nLines
        f = fullfile(folder, sprintf(pattern, i));
        if ~isfile(f)
            error("Missing file: %s", f);
        end

        T = readtable(f);
        if width(T) < max(colDist, colElev)
            error("File %s has %d columns, need at least %d.", f, width(T), max(colDist, colElev));
        end

        dist = double(T{:, colDist});
        elev = double(T{:, colElev});

        % Remove NaNs/Inf (paired)
        ok = isfinite(dist) & isfinite(elev);
        dist = dist(ok);
        elev = elev(ok);

        if numel(dist) < 2
            error("Not enough valid samples in %s.", f);
        end

        distCell{i} = dist(:);
        elevCell{i} = elev(:);
    end
end

function plotOneProfile(x, y, clipMinElev, fillColor, fillAlpha, lineWidth, ...
                        fontName, fontSize, gridStyle, gridColor)
    % Sort by distance
    [x, ix] = sort(x);
    y = y(ix);

    % Optional clip
    if ~isempty(clipMinElev)
        y = max(clipMinElev, y);
    end

    % Filled area
    h = area(x, y);
    set(h, 'FaceColor', fillColor, 'FaceAlpha', fillAlpha, 'EdgeColor','none');
    hold on;

    % Profile line
    plot(x, y, 'k-', 'LineWidth', lineWidth);

    % Cosmetics
    xlim([min(x) max(x)]);
    box on;

    set(gca, 'FontName', fontName, 'FontSize', fontSize, ...
        'XGrid','on','YGrid','on', ...
        'GridLineStyle', gridStyle, 'GridColor', gridColor);
end

function exportFigure(fig, outFile, dpi, useExportFig, transparentBG)
    arguments
        fig
        outFile (1,1) string
        dpi (1,1) double {mustBePositive}
        useExportFig (1,1) logical
        transparentBG (1,1) logical
    end

    % Prefer export_fig if available
    hasExportFig = exist('export_fig', 'file') == 2;

    if useExportFig && hasExportFig
        set(fig, 'InvertHardcopy','off');
        if transparentBG
            export_fig(outFile, '-png', sprintf('-r%d', dpi), '-transparent');
        else
            export_fig(outFile, '-png', sprintf('-r%d', dpi));
        end
        return;
    end

    % Fallback: built-in exportgraphics (R2020a+)
    if transparentBG
        set(fig, 'Color','none');
    end

    try
        exportgraphics(fig, outFile, 'Resolution', dpi, 'BackgroundColor','none');
    catch
        % Older MATLAB fallback
        warning("exportgraphics not available. Using print() as fallback.");
        if transparentBG
            set(fig, 'InvertHardcopy','off');
        end
        print(fig, outFile, '-dpng', sprintf('-r%d', dpi));
    end
end
