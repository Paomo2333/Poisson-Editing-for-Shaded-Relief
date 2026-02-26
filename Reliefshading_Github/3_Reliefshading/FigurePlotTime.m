%% plot_poisson_time_sensitivity.m
% Poisson runtime sensitivity vs error tolerance (log-x, reversed axis).
%
% Input (relative to this script):
%   ./Sensitivetime_Data/Poisson_time_summary.mat  (contains table T)
%
% Output:
%   ./Sensitivetime_Data/Fig_Poisson_time_sensitivity.png
%
% Author: Yibo Li / Sun Yat-sen University
% -------------------------------------------------------------------------

clc; clear; close all;

%% ===================== Paths (project-root relative) =====================

% Absolute path of THIS file
thisFile = which(mfilename);


% Script folder
scriptDir = fileparts(thisFile);

% Project root (one level up from src)
projectRoot = fileparts(scriptDir);

% Data folder
dataFolder = fullfile(projectRoot, "Sensitivetime_Data");

matFile = fullfile(dataFolder, "Poisson_time_summary.mat");

% Check
if ~isfolder(dataFolder)
    error("Data folder not found:\n%s", dataFolder);
end

if ~isfile(matFile)
    error("MAT file not found:\n%s", matFile);
end

%% ===================== Load data =====================
S = load(matFile, "T");
if ~isfield(S, "T")
    error("MAT file does not contain variable 'T': %s", matFile);
end
T = S.T;

reqVars = ["Tolerance", "Time_315_45_s", "Time_315_270_s"];
for v = reqVars
    if ~ismember(v, string(T.Properties.VariableNames))
        error("Table T missing required variable: %s", v);
    end
end

tols    = T.Tolerance;
t31545  = T.Time_315_45_s;
t315270 = T.Time_315_270_s;

% Basic cleaning
ok = isfinite(tols) & isfinite(t31545) & isfinite(t315270) & (tols > 0);
tols    = tols(ok);
t31545  = t31545(ok);
t315270 = t315270(ok);

if numel(tols) < 2
    error("Not enough valid records after cleaning.");
end

%% ===================== Sort by tolerance =====================
[xtols, idx] = sort(tols);
y31545  = t31545(idx);
y315270 = t315270(idx);

%% ===================== Plot =====================
fig = figure('Color','w', 'Units','centimeters', 'Position',[3 3 10 8]);

semilogx(xtols, y31545, '-o', ...
    'LineWidth', 1.2, 'MarkerSize', 5, 'MarkerFaceColor', 'w');
hold on;

semilogx(xtols, y315270, '-s', ...
    'LineWidth', 1.2, 'MarkerSize', 5, 'MarkerFaceColor', 'w');

set(gca, 'XDir', 'reverse');

xlabel('Error tolerance', 'FontName','Times New Roman', 'FontSize',14);
ylabel('Runtime (s)',      'FontName','Times New Roman', 'FontSize',14);

set(gca, 'XScale','log', ...
         'FontName','Times New Roman', 'FontSize',11);

% Use explicit ticks if the set is small; otherwise let MATLAB decide
if numel(xtols) <= 12
    set(gca, 'XTick', xtols);
    xticklabels(cellstr(num2str(xtols, '%.0e')));
end

grid on; box on;

legend({'First Poisson editing', 'Second Poisson editing'}, ...
    'Location','northwest', 'Box','off', ...
    'FontName','Times New Roman', 'FontSize',12, ...
    'Interpreter','tex');

xlim([min(xtols)*0.9, max(xtols)*1.1]);
ylim([0, max([y31545; y315270]) * 1.1]);

%% ===================== Export =====================
outFile = fullfile(dataFolder, "Fig_Poisson_time_sensitivity.png");
exportPng(fig, outFile, 800, true);

fprintf("Done. Saved: %s\n", outFile);

%% ===================== Local function =====================
function exportPng(fig, outFile, dpi, transparentBG)
    arguments
        fig
        outFile (1,1) string
        dpi (1,1) double {mustBePositive}
        transparentBG (1,1) logical
    end

    hasExportFig = exist('export_fig', 'file') == 2;

    if hasExportFig
        set(fig, 'InvertHardcopy','off');
        if transparentBG
            set(fig, 'Color','none');
            ax = findall(fig,'Type','axes');
            set(ax, 'Color','none');
            export_fig(outFile, '-png', sprintf('-r%d', dpi), '-transparent');
        else
            export_fig(outFile, '-png', sprintf('-r%d', dpi));
        end
        return;
    end

    % Fallback: exportgraphics (R2020a+) / print
    if transparentBG
        set(fig, 'Color','none');
        ax = findall(fig,'Type','axes');
        set(ax, 'Color','none');
        bg = 'none';
    else
        bg = 'white';
    end

    try
        exportgraphics(fig, outFile, 'Resolution', dpi, 'BackgroundColor', bg);
    catch
        warning("exportgraphics not available. Using print() fallback.");
        set(fig, 'InvertHardcopy','off');
        print(fig, outFile, '-dpng', sprintf('-r%d', dpi));
    end
end
