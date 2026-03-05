function outSig = HC(inSig, params)
    % HC: Hard Clipper (for complex signals)
    % Input:
    %   inSig: input signal (can be complex)
    %   params: parameters structure containing 'ClipMax', 'showFig', and 'timeEnd'
    % Output:
    %   outSig: clipped output signal

    ClipMax = params.ClipMax;  % 获取裁剪因子
    showFig = params.showFig;  % 是否显示图形
    timeEnd = params.timeEnd;  % 时间结束点

    % 计算复信号的幅度
    magSig = abs(inSig);  % 信号幅度

    % 初始化输出信号
    outSig = inSig;  % 默认情况下，输出信号等于输入信号

    % 对于超过裁剪阈值的信号进行裁剪
    % 判断幅度大于ClipMax的信号
    exceedIdx = magSig > ClipMax;

    % 对超过阈值的信号进行裁剪
    if any(exceedIdx)
        % 计算裁剪后的实部和虚部
        clippedReal = ClipMax * real(inSig(exceedIdx)) ./ magSig(exceedIdx);
        clippedImag = ClipMax * imag(inSig(exceedIdx)) ./ magSig(exceedIdx);

        % 更新裁剪后的信号
        outSig(exceedIdx) = clippedReal + 1i * clippedImag;
    end

    % 绘图显示输入信号和输出信号的差异
    if showFig
        T_title = sprintf("Hard Clipping with %.2f", ClipMax);  % 设置标题
        figure('Name', T_title);
        t = linspace(0, timeEnd, length(inSig(:)));  % 时间向量
        cutLine = ClipMax * ones(size(inSig(:)));  % 剪切线
        
        hold on;
        plot(t, abs(inSig(:)), 'b');  % 原信号幅度
        plot(t, abs(outSig(:)), 'r');  % 剪切后的信号幅度
        plot(t, cutLine, 'k--');  % 剪切线
        hold off;

        legend('Origin Signal', 'Signal W. HC', 'Cut Line');
        title('HC Performance');
        
        % 保存图像
        if params.save == 1
            saveas(gcf, sprintf("%s/%s", params.save_path, T_title), params.save_fmt);
        end
    end
end
