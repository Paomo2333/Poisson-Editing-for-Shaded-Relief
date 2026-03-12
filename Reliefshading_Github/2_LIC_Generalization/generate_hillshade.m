function hs = generate_hillshade(z, az, el, vert_exag)
    % 参数说明：
    % z - 高程矩阵
    % az - 太阳方位角（度）
    % el - 太阳高度角（度）
    % vert_exag - 垂直夸大因子

    % 高程放大
    z = z * vert_exag;
    
    % 计算梯度
    [dzdx, dzdy] = gradient(z);
    
    % 计算坡度和坡向
    slope = atan(sqrt(dzdx.^2 + dzdy.^2));
    aspect = atan2(dzdy, -dzdx);
    
    % 转换太阳角度为弧度
    az_rad = deg2rad(az);
    el_rad = deg2rad(el);
    
    % 计算光照强度
    hs = sin(el_rad) * sin(slope) + ...
         cos(el_rad) * cos(slope) .* ...
         cos(az_rad - aspect);
    
    % 归一化到0-1范围
    hs = (hs - min(hs(:))) / (max(hs(:)) - min(hs(:)));
end