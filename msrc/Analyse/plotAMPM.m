function plotAMPM(inSig, outSig, tit, normalize)
    % plotAMPM: Plot AM-PM characteristics for ideal linear PA
    %   inSig: input signal
    %   outSig: output signal
    %   tit: plot title (string)
    %   normalize: 是否归一化信号 (true/false, optional, default=true)

    % 确保输入和输出信号是行向量
    inSig = reshape(inSig, 1, []);  
    outSig = reshape(outSig, 1, []); 

    % 检查 normalize 参数，如果没有输入，则默认归一化
    if nargin < 4
        normalize = true;
    end

    % ========================== 数据预处理 ==========================
    % 根据 normalize 参数决定是否归一化
    if normalize
        % 归一化信号到峰值
        in_amp = abs(inSig) / max(abs(inSig));
        xlabel_str = 'Normalized Input Amplitude';
        ylabel_str = 'Normalized Output Amplitude';
    else
        % 使用原始幅度
        in_amp = abs(inSig);
        xlabel_str = 'Input Amplitude';
        ylabel_str = 'Output Amplitude';
    end
    
    % 计算相位差（AM-PM）
    theta_in = angle(inSig);  % 输入信号的相位
    theta_out = angle(outSig);  % 输出信号的相位
    theta_deg = rad2deg(theta_out - theta_in);  % 相位差，单位：度

    % 将相位差限制在 [-180, 180] 范围内
    theta = wrapTo180(theta_deg);

    % ========================== 绘图 ==========================
    % 创建图形
    figure("Name", tit);
    
    % 绘制散点图
    scatter(in_amp, theta, 25, 'filled', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none');
    hold on;  % 保持绘图，添加理想线

    % 绘制理想线（y = 0，即理想线性功率放大器）
    plot(in_amp, zeros(size(in_amp)), 'LineWidth', 2);  % 理想AM/PM线（y = 0）

    % 设置标签和标题
    title(tit, 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(ylabel_str, 'FontSize', 12);
    xlabel(xlabel_str, 'FontSize', 12);

    % 设置坐标轴范围
    axis tight;  % 自动调整坐标轴范围以适应数据
    grid on;  % 可选：添加网格线以增强可读性

    % 添加图例
    legend('Measured AM/PM', 'Ideal Linear PA Line', 'Location', 'Best', 'FontSize', 12, 'Box', 'on');

    % 设置背景颜色
    set(gca, 'Color', [0.95 0.95 0.95]);  % 轻灰色背景

    % 调整图形大小，便于阅读
    set(gcf, 'Position', [100, 100, 600, 400]);

    % 释放绘图 hold
    hold off;  
end
