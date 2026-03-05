function plotMultiplePSDsNormalized(plotTitle, signals, labels)
    % plotMultiplePSDsNormalized 使用 pwelch 绘制多个信号的归一化频率 PSD
    %
    %   语法：
    %       plotMultiplePSDsNormalized(plotTitle, signals, labels)
    %
    %   输入参数：
    %       plotTitle - 字符串，图形标题。
    %       signals   - cell 数组，每个元素为一个数值向量，代表一个信号
    %       labels    - cell 数组，每个元素为对应信号的标签，长度必须与 signals 相同
    %
    %
    %   说明：
    %       pwelch 在未指定采样率时返回归一化的角频率（单位：rad/sample），
    %       通过除以 π 将其转换为归一化频率，范围 0 到 1，其中 1 对应 π rad/sample。
    
    
    % 检查 signals 和 labels 是否为 cell 数组且长度一致
    if ~iscell(signals)
        error('signals 必须为 cell 数组，每个 cell 内部为一个信号向量。');
    end
    if ~iscell(labels)
        error('labels 必须为 cell 数组。');
    end
    if length(signals) ~= length(labels)
        error('signals 与 labels 的长度必须一致。');
    end
    
    % 创建新图形窗口并保持绘图
    figure("Name",plotTitle);
    hold on;
    
    % 遍历每个信号进行 PSD 计算和绘图
    for k = 1:length(signals)
        signal = reshape(signals{k},1,{});
        % 检查信号是否为数值向量
        if ~isvector(signal) || ~isnumeric(signal)
            error('每个信号必须为数值向量。');
        end
        
        % 调用 pwelch 计算 PSD
        % 不指定采样率 fs，则返回的频率 w 单位为 rad/sample（归一化角频率）
        [pxx, w] = pwelch(signal);
        
        % 将归一化角频率转换为归一化频率（范围 0~1，1 对应 π rad/sample）
        normFreq = w / pi;
        
        % 绘制 PSD 曲线（转换为 dB 单位）
        plot(normFreq, 10*log10(pxx), 'LineWidth', 1.5);
    end
    
    % 设置图形的标签、标题和图例
    xlabel('Normalized Frequency (×π rad/sample)');
    ylabel('PSD (dB/Hz)');
    title(plotTitle);
    legend(labels, 'Location', 'Best');
    grid on;
    hold off;
end
