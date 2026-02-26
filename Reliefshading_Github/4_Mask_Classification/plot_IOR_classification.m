%% ========================================================================
%  plot_IOR_classification.m
%
%  Purpose:
%  Visualize IOR (Index of Rock) raster, histogram, and binary classification.
%
%  Output:
%  - 3-panel figure (spatial distribution, histogram, classification)
%  - High-resolution PNG export
%
%  Author: Li Yibo
%  ========================================================================

clc; clear; close all;

%% ====================== 1. Project paths ======================

% Get current script location
if isempty(mfilename)
    % Running as script from command window
    projectRoot = pwd;
else
    projectRoot = fileparts(mfilename('fullpath'));
end

dataDir = fullfile(projectRoot, 'Rock_index_histogram');
outDir  = fullfile(projectRoot, 'figures');

if ~exist(outDir,'dir')
    mkdir(outDir);
end

inFile = fullfile(dataDir, 'rock_index.tif');

% Check file existence
if ~isfile(inFile)
    error('Input file not found: %s', inFile);
end
%% ====================== 2. Parameters =========================
threshold = 1.1;

fontName  = 'Arial';
fontSize  = 14;
titleSize = 15;
tagSize   = 20;

customColormap = [
    1.0 1.0 1.0;    % 0: NoData
    0.7 0.7 1.0;    % 1: Snow/Ice
    1.0 0.7 0.7     % 2: Bare Rock
];

%% ====================== 3. Read raster ========================
[rock_idx, R] = readgeoraster(inFile);
rock_idx = double(rock_idx);

rock_idx(rock_idx == 99) = NaN;

[X,Y] = worldGrid(R);

%% ====================== 4. Classification =====================
classified_mask = zeros(size(rock_idx));
classified_mask(rock_idx < threshold)  = 1;
classified_mask(rock_idx >= threshold) = 2;
classified_mask(isnan(rock_idx))       = 0;

valid_data = rock_idx(~isnan(rock_idx));

%% ====================== 5. Figure =============================

fig = figure('Units','centimeters','Position',[2 2 35 20]);
t = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

%% ---------------------- (a) Spatial IOR -----------------------
axA = nexttile(t,1,[2 2]);

hImg = imagesc(X(1,:),Y(:,1),rock_idx);
axis xy tight
grid on

axA.FontName = fontName;
axA.FontSize = fontSize;
axA.GridLineStyle = '--';
axA.LineWidth = 1.2;

title('Spatial Distribution of IOR','FontWeight','bold','FontSize',titleSize)
xlabel('X (m)')
ylabel('Y (m)')

set(hImg,'AlphaData',~isnan(rock_idx))
colormap(axA,gray)
caxis(axA,[0 3])

% ---- manual colorbar (publication style) ----
cb = colorbar(axA);
cb.Units = 'normalized';
cb.Location = 'manual';

axPos = axA.Position;
w = 0.012;
h = 0.25 * axPos(4);
pad = 0.02;

cb.Position = [
    axPos(1)+axPos(3)-w-pad, ...
    axPos(2)+axPos(4)-h-pad, ...
    w, h];

cb.TickDirection = 'out';
cb.Box = 'on';
cb.FontName = fontName;
cb.FontSize = fontSize;

text(axA,0.02,0.98,'(a)','Units','normalized',...
    'FontSize',tagSize,...
    'HorizontalAlignment','left','VerticalAlignment','top');

%% ---------------------- (b) Histogram -------------------------
axB = nexttile(t,3);

% 使用更合理 bin 数（Freedman–Diaconis rule）
binWidth = 2*iqr(valid_data)/(numel(valid_data)^(1/3));
nBins = max(50, round((max(valid_data)-min(valid_data))/binWidth));

histogram(valid_data,nBins,'Normalization','probability',...
    'FaceColor',[0.5 0.5 0.5],'EdgeColor','black');
hold on

hTh = xline(threshold,'--k','LineWidth',1.8);

xlabel('Pixel Value')
ylabel('Probability')
xlim([0 3])
grid on

axB.FontName = fontName;
axB.FontSize = fontSize;
axB.GridLineStyle = '--';
axB.LineWidth = 1.2;

title('Histogram of IOR','FontWeight','bold','FontSize',titleSize)

legend(hTh,sprintf('Threshold = %.2f',threshold),...
    'Location','northeast','Box','on',...
    'FontName',fontName,'FontSize',fontSize)

text(axB,0.02,0.98,'(b)','Units','normalized',...
    'FontSize',tagSize,...
    'HorizontalAlignment','left','VerticalAlignment','top');

%% ---------------------- (c) Classification --------------------
axC = nexttile(t,6);

imagesc(X(1,:),Y(:,1),classified_mask);
axis xy tight
grid on

colormap(axC,customColormap)
caxis([0 2])

axC.FontName = fontName;
axC.FontSize = fontSize;
axC.GridLineStyle = '--';
axC.LineWidth = 1.2;

title('Classified Surface Types','FontWeight','bold','FontSize',titleSize)
xlabel('X (m)')
ylabel('Y (m)')

% legend via dummy patches
hSnow = patch(NaN,NaN,customColormap(2,:),'EdgeColor','k');
hRock = patch(NaN,NaN,customColormap(3,:),'EdgeColor','k');

legend([hSnow,hRock],{'Snow/Ice','Bare Rock'},...
    'Location','northeast','Box','on',...
    'FontName',fontName,'FontSize',fontSize)

colorbar('off')

text(axC,0.02,0.98,'(c)','Units','normalized',...
    'FontSize',tagSize,...
    'HorizontalAlignment','left','VerticalAlignment','top');

%% ====================== 6. Export =============================

outFile = fullfile(outDir,'IOR_classification_3panel.png');

exportgraphics(fig,outFile,...
    'Resolution',800,...
    'BackgroundColor','white');

fprintf('Figure saved to:\n%s\n', outFile);