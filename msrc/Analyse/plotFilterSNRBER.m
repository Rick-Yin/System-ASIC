clear;

% 滤波器选择列表
filters = {"RootRaisedCosine", "IdealRect", "RaisedCosine", "Window", "NoFilter"};

SNR = -20:20;  % 信噪比范围
rep = 10;  % 重复次数
EB = zeros(length(filters), length(SNR));  % 存储不同滤波器对应的BER值

% 遍历每种滤波器
for f = 1:length(filters)
    % 根据当前滤波器选择相应的参数
    params = genParams(filters{f});  % 调用getParams来设置当前滤波器
    
    % 进行多次重复实验
    for r = 1:rep
        for i = 1:length(SNR)
            % 生成基带信号
            [BasebandParam, BasebandSig, BasebandProcessData] = BaseBand_LDPC(params);
            
            % 信号通过信道
            sig_before_channel = BasebandSig;
            sig_after_channel = awgn(sig_before_channel, SNR(i), "measured");
            
            % 接收信号并进行解调
            [RecvSig, RecvProcessData] = Recv_LDPC(params, BasebandParam, sig_after_channel);
            
            % 累计BER
            EB(f, i) = EB(f, i) + biterr(BasebandProcessData.SourceSig, RecvSig);
        end
    end
    
    % 计算平均BER
    EB(f, :) = (EB(f, :) / rep) / length(RecvSig);
end

% 绘制不同滤波器下的SNR-BER图
figure;
hold on;
colors = ['r', 'g', 'b', 'm', 'c'];  % 给每个滤波器分配颜色
for f = 1:length(filters)
    plot(SNR, EB(f, :), 'Color', colors(f), 'DisplayName', filters{f});
end
hold off;
legend;
xlabel('SNR (dB)');
ylabel('BER');
title('SNR vs BER for Different Filters');
grid on;
