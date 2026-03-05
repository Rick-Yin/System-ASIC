function plotAMAM(inSig, outSig, tit, normalize)
    % plotAMAM: Plot AM-AM characteristics
    %   inSig: input signal (complex)
    %   outSig: output signal (complex)
    %   tit: plot title (string)
    %   normalize: 是否归一化信号 (true/false, optional, default=true)
    
    % ========================== 参数处理 ==========================
    % 检查 normalize 参数是否存在，若未输入则默认归一化
    if nargin < 4
        normalize = true;
    end
    
    % ========================== 数据预处理 ==========================
    % 确保输入信号为行向量
    inSig = reshape(inSig, 1, []);  
    outSig = reshape(outSig, 1, []); 

    % 根据 normalize 参数决定是否归一化
    if normalize
        % 归一化到峰值
        in_amp = abs(inSig) / max(abs(inSig));
        out_amp = abs(outSig) / max(abs(outSig));
        xlabel_str = 'Normalized Input Amplitude';
        ylabel_str = 'Normalized Output Amplitude';
    else
        % 使用原始幅度
        in_amp = abs(inSig);
        out_amp = abs(outSig);
        xlabel_str = 'Input Amplitude';
        ylabel_str = 'Output Amplitude';
    end
    
    % ========================== 绘图 ==========================
    figure("Name", "AM/AM");
    
    % 绘制散点图
    scatter(in_amp, out_amp, 25, 'filled', 'MarkerFaceAlpha', 0.6);  
    hold on; 

    % 线性拟合
    p = polyfit(in_amp, out_amp, 1);  
    idealLine = polyval(p, in_amp);  
    plot(in_amp, idealLine, 'LineWidth', 2); 

    % 标签和标题
    title(tit, 'FontSize', 14, 'FontWeight', 'bold');
    ylabel(ylabel_str, 'FontSize', 12);
    xlabel(xlabel_str, 'FontSize', 12);

    % 坐标轴范围
    if normalize
        xlim([0, 1]);
        ylim([0, 1]);
    else
        % 自动调整范围，但保证包含原点
        xlim([0, max(in_amp)*1.1]);
        ylim([0, max(out_amp)*1.1]);
    end
    
    grid on; 
    legend('Measured AM/AM', 'Ideal PA Line', 'Location', 'Best', 'FontSize', 12, 'Box', 'on');
    set(gcf, 'Position', [100, 100, 600, 400]);
    hold off; 
end