function Hn = minmaxNormalize(H, epsDen)
%MINMAXNORMALIZE Normalize array to [0,1] using min-max scaling
%
%   Hn = minmaxNormalize(H, epsDen)
%
%   epsDen: small threshold to avoid division by zero
%
%   If dynamic range is smaller than epsDen,
%   output will be zeros.

    mn = min(H(:));
    mx = max(H(:));
    den = mx - mn;

    if den < epsDen
        Hn = zeros(size(H));
    else
        Hn = (H - mn) ./ den;
    end

end