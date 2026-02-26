function exportPng(figHandle, outFile, dpi, transparentBG)
%EXPORTPNG Export figure to PNG with optional transparency
%
%   exportPng(figHandle, outFile, dpi, transparentBG)
%
%   - Uses export_fig if available
%   - Otherwise falls back to exportgraphics
%   - Final fallback: print()
%
%   transparentBG: true/false

    if exist('export_fig', 'file') == 2
        set(figHandle, 'InvertHardcopy', 'off');

        if transparentBG
            set(figHandle, 'Color', 'none');
            ax = findall(figHandle, 'Type', 'axes');
            set(ax, 'Color', 'none');
            export_fig(outFile, '-png', sprintf('-r%d', dpi), '-transparent');
        else
            export_fig(outFile, '-png', sprintf('-r%d', dpi));
        end
        return;
    end

    % exportgraphics fallback
    if transparentBG
        set(figHandle, 'Color', 'none');
        ax = findall(figHandle, 'Type', 'axes');
        set(ax, 'Color', 'none');
        bg = 'none';
    else
        bg = 'white';
    end

    try
        exportgraphics(figHandle, outFile, ...
            'Resolution', dpi, ...
            'BackgroundColor', bg);
    catch
        warning('exportgraphics unavailable. Using print fallback.');
        set(figHandle, 'InvertHardcopy', 'off');
        print(figHandle, outFile, '-dpng', sprintf('-r%d', dpi));
    end

end