function H = sanitizeHillshade(H)
%SANITIZEHILLSHADE Convert hillshade to double and normalize to [0,1]
%
%   H = sanitizeHillshade(H)
%
%   - Converts input to double
%   - Replaces NaN/Inf with 0
%   - Normalizes 0–255 (or arbitrary max) to [0,1]
%   - Clamps values into [0,1]
%
%   Suitable for hillshade rasters before Poisson editing.

    % Convert to double
    H = double(H);

    % Replace invalid values
    H(~isfinite(H)) = 0;

    % Normalize if likely 0–255 input
    maxVal = max(H(:));
    if maxVal > 1
        if maxVal > 0
            H = H ./ maxVal;
        end
    end

    % Clamp to [0,1]
    H = max(0, min(1, H));

end