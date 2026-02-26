function R = Possion_edit(dst, src, eps)
    % Poisson editing of DST using SRC
    % DST  - 2d grid (destination)
    % SRC  - 2d grid (source)
    % EPS  - Residual error threshold for termination

    [H, W] = size(dst);  % height, width
    % Initialize the right-hand side of Poisson equation
    f = zeros(H, W);
    for i = 2:H-1
        for j = 2:W-1
            f(i,j) = blend_max(dst, src, i, j);  % Compute blend_max for each pixel
        end
    end

    % Initial solution and output
    R = dst;

    % Iterative solution using Gauss-Seidel method
    while true
        residual = 0;
        for i = 2:H-1
            for j = 2:W-1
                R_old = R(i,j);  % Save old state
                R(i,j) = (R(i+1,j) + R(i-1,j) + R(i,j+1) + R(i,j-1) - f(i,j)) / 4;
                residual = residual + (R_old - R(i,j))^2;  % Residual sum of squares
            end
        end

        % Check if the residual is below the threshold
        if residual < eps
            break;
        end
    end
end

function r = blend_max(dst, src, i, j)
    % Right-hand side of Poisson equation.
    % Sum of absolute maximum of DST and SRC in 4-neighborhood.

    [H, W] = size(dst);  % height, width
    r = 0;

    % For 4-neighborhood: (i-1,j), (i+1,j), (i,j-1), (i,j+1)
    for p = [i-1, i+1]
        for q = [j-1, j+1]
            if p > 0 && p <= H && q > 0 && q <= W
                s = src(p,q) - src(i,j);
                d = dst(p,q) - dst(i,j);
                if abs(s) > abs(d)
                    r = r + s;
                else
                    r = r + d;
                end
            end
        end
    end
end
