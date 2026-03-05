% 多载波聚合仿真（修正完整版）
clear; clc; close all;

%% 参数设置
N_carriers = 10;                     % 子载波数量
Nfft = 256;                         % FFT点数
cp_len = 16;                        % 循环前缀长度
mod_order = 64;                     % 调制阶数
num_symbols = 50;                   % 每个载波的OFDM符号数（减少仿真时间）
SNR_dB = 0:2:30;                    % 信噪比范围
fs_sub = 30.72e6;                   % 子载波采样率
fs_total = 409.6e6;                 % 总采样率（满足200MHz*2）
delta_f = fs_sub / Nfft;            % 子载波间隔120kHz
dc_pos = Nfft/2 + 1;                % DC子载波位置
data_idx = [2:dc_pos-1 dc_pos+1:dc_pos+80]; % 161个有效子载波（排除DC）
bits_per_symbol = log2(mod_order);
num_bits_per_ofdm = bits_per_symbol * length(data_idx);

%% 滤波器设计
% 发送端升余弦滤波器
beta = 0.25;                        % 滚降系数
span = 6;                           % 滤波器跨度
L = ceil(fs_total / fs_sub);              % 插值倍数(409.6/30.72=13.333)
tx_filter = rcosdesign(beta, span, L, 'sqrt');

% 接收端低通滤波器
lpFilt = designfilt('lowpassfir', ...
    'PassbandFrequency',19e6, ...
    'StopbandFrequency',21e6, ...
    'PassbandRipple',0.1, ...
    'StopbandAttenuation',80, ...
    'DesignMethod','kaiserwin', ...
    'SampleRate', fs_total);

%% 初始化BER
ber = zeros(length(SNR_dB), N_carriers);

%% 主循环（SNR扫描）
for idx_snr = 1:length(SNR_dB)
    snr = SNR_dB(idx_snr);
    fprintf('\nProcessing SNR = %d dB...\n', snr);
    
    %% ================= 发送端 =================
    tx_all = [];
    tx_bits_all = cell(N_carriers, 1);
    
    for c = 1:N_carriers
        %% 生成数据
        num_bits = num_bits_per_ofdm * num_symbols;
        tx_bits = randi([0 1], num_bits, 1);
        tx_bits_all{c} = tx_bits;
        
        %% QAM调制
        bits_matrix = reshape(tx_bits, bits_per_symbol, []).';
        qam_symbols = qammod(bi2de(bits_matrix), mod_order, 'UnitAveragePower', true);
        
        %% OFDM调制
        tx_signal = zeros(num_symbols*(Nfft+cp_len), 1);
        for k = 1:num_symbols
            Xk = zeros(Nfft,1);
            idx = (k-1)*length(data_idx) + (1:length(data_idx));
            Xk(data_idx) = qam_symbols(idx);
            
            x_time = ifft(Xk, Nfft);
            x_cp = [x_time(end-cp_len+1:end); x_time];
            tx_signal((k-1)*(Nfft+cp_len)+1:k*(Nfft+cp_len)) = x_cp;
        end
        
        %% 上采样与频移
        % 升余弦插值上采样
        tx_upsampled = upfirdn(tx_signal, tx_filter, L, 1);
        
        % 频移（数字上变频）
        t = (0:length(tx_upsampled)-1).' / fs_total;
        f_c = (c-1)*20e6;                  % 子带中心频率
        tx_shifted = tx_upsampled .* exp(1j*2*pi*f_c*t);
        tx_shifted = tx_shifted / sqrt(N_carriers); % 功率归一化
        
        %% 信号叠加
        if isempty(tx_all)
            tx_all = tx_shifted;
        else
            min_len = min(length(tx_all), length(tx_shifted));
            tx_all = tx_all(1:min_len) + tx_shifted(1:min_len);
        end
    end
    
    %% 添加AWGN
    rx_all = awgn(tx_all, snr, 'measured');
    
    %% ================= 接收端 =================
    for c = 1:N_carriers
        %% 数字下变频
        t = (0:length(rx_all)-1).' / fs_total;
        f_c = (c-1)*20e6;
        rx_baseband = rx_all .* exp(-1j*2*pi*f_c*t);
        
        %% 低通滤波
        rx_filtered = filtfilt(lpFilt, rx_baseband);
        
        %% 下采样
        rx_downsampled = rx_filtered(1:L:end); % 简单抽取
        
        %% 符号同步
        % 使用循环前缀进行相关同步
        corr_len = 1000; % 相关窗口长度
        corr = abs(conv(rx_downsampled(1:corr_len), conj(flipud(rx_downsampled(1:cp_len)))));
        [~, max_pos] = max(corr);
        sync_offset = max_pos - cp_len;
        
        %% 裁剪同步后信号
        sync_signal = rx_downsampled(sync_offset+1:end);
        total_samples = floor(length(sync_signal)/(Nfft+cp_len))*(Nfft+cp_len);
        sync_signal = sync_signal(1:total_samples);
        
        %% OFDM解调
        rx_matrix = reshape(sync_signal, Nfft+cp_len, []);
        rx_no_cp = rx_matrix(cp_len+1:end, :);
        rx_fft = fft(rx_no_cp, Nfft, 1);
        
        %% 相位补偿（使用导频）
        % 假设第一个符号包含导频（实际应设计导频图样）
        pilot_symbols = rx_fft(data_idx(1:10:end), 1); % 抽取部分子载波作为导频
        phase_error = angle(pilot_symbols) - angle(qam_symbols(1:length(pilot_symbols)));
        avg_phase = mean(phase_error);
        rx_fft = rx_fft * exp(-1j*avg_phase); % 相位补偿
        
        %% 数据提取
        rx_data = rx_fft(data_idx, :);
        rx_data = rx_data(:);
        
        %% QAM解调
        rx_data = rx_data / std(rx_data); % 功率归一化
        rx_symbols = qamdemod(rx_data, mod_order, 'UnitAveragePower', true);
        rx_bits = de2bi(rx_symbols, bits_per_symbol, 'left-msb').';
        rx_bits = rx_bits(:);
        
        %% BER计算
        ref_bits = tx_bits_all{c}(1:length(rx_bits));
        ber(idx_snr, c) = sum(ref_bits ~= rx_bits) / length(ref_bits);
    end
    
    fprintf('SNR = %d dB, 平均BER = %.4f\n', snr, mean(ber(idx_snr, :)));
end

%% 结果可视化
figure;
semilogy(SNR_dB, mean(ber,2), 'bo-', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('误码率 (BER)');
title('10x20MHz载波聚合系统性能 (64QAM-OFDM)');
legend('仿真结果', 'Location', 'southwest');

%% 理论BER曲线（对比）
theory_ber = berawgn(SNR_dB, 'qam', mod_order);
hold on;
semilogy(SNR_dB, theory_ber, 'r--', 'LineWidth', 1.5);
legend('仿真结果', '理论值', 'Location', 'southwest');

disp('仿真完成。');