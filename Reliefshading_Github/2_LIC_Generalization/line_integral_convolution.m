function z2 = line_integral_convolution(z, Vx, Vy, L, ds)
    % LINE_INTEGRAL_CONVOLUTION Applies line integral convolution to a raster.
    %
    %   z2 = LINE_INTEGRAL_CONVOLUTION(z, Vx, Vy, L, ds)
    %
    %   Inputs:
    %       z  - Elevation raster (2D matrix)
    %       Vx - Vector field component in the x-direction (same size as z)
    %       Vy - Vector field component in the y-direction (same size as z)
    %       L  - Integration length (number of steps forward and backward)
    %       ds - Integration step size
    %
    %   Output:
    %       z2 - Processed raster after line integral convolution

    % 初始化输出栅格
    z2 = z; 
    [H, W] = size(z); % 栅格高度和宽度

    for i = 1:H
        for j = 1:W
            s = double(z(i, j)); % 当前高程值
            n = 1; % 样本计数

            %% 前向积分
            p = i;
            q = j;
            y = i + 0.5;
            x = j + 0.5;
            for k = 1:L
                if p >=1 && p <= H && q >=1 && q <= W
                    % 检查 Vx 和 Vy 是否为 NaN
                    if isnan(Vx(p, q)) || isnan(Vy(p, q))
                        break; % 遇到 NaN，停止前向积分
                    end

                    y = y + ds * Vy(p, q);
                    x = x + ds * Vx(p, q);
                    p_new = round(y);
                    q_new = round(x);
                    if p_new < 1 || p_new > H || q_new < 1 || q_new > W
                        break; % 超出边界，退出
                    end
                    p = p_new;
                    q = q_new;
                    s = s + double(z(p, q));
                    n = n + 1;
                else
                    break; % 超出边界，退出
                end
            end

            %% 反向积分：沿负向向量场积分
            p = i;
            q = j;
            y = i + 0.5;
            x = j + 0.5;
            for k = 1:L
                if p >=1 && p <= H && q >=1 && q <= W
                    % 检查 Vx 和 Vy 是否为 NaN
                    if isnan(Vx(p, q)) || isnan(Vy(p, q))
                        break; % 遇到 NaN，停止反向积分
                    end

                    y = y - ds * Vy(p, q);
                    x = x - ds * Vx(p, q);
                    p_new = round(y);
                    q_new = round(x);
                    if p_new < 1 || p_new > H || q_new < 1 || q_new > W
                        break; % 超出边界，退出
                    end
                    p = p_new;
                    q = q_new;
                    s = s + double(z(p, q));
                    n = n + 1;
                else
                    break; % 超出边界，退出
                end
            end

            % 计算平均值并赋值给输出栅格
            if n > 0
                z2(i, j) = s / n;
            else
                z2(i, j) = z(i, j); % 如果没有积累值，则保持原值
            end
        end
    end
end
