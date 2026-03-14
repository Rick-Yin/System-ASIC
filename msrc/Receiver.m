function [decoded_bits, rx_metrics] = Receiver(rx_sum, params)
    decoded_bits = zeros((params.mod.K * 5) * params.ofdm.numSymbols * params.rf.numCarriers * params.mod.bits_per_sym / 4, 1);
    info_ptr = 1;
    IterAllNum = params.ofdm.numSymbols * params.mod.bits_per_sym / 4;
    ref_symbols_all = complex([], []);
    rx_symbols_all = complex([], []);
    % PA process
    rx_sum = rx_sum / sqrt(mean(abs(rx_sum).^2));

    for k = 1:params.rf.numCarriers
        t = (0:length(rx_sum)-1)' / params.rf.Fs_total;
        rx_baseband = rx_sum .* exp(-1j*2*pi*params.rf.f_center(k)*t);
        rx_matched = conv(rx_baseband, params.filter.active_coeffs, 'same');

        %% Plot frequency spectrum before and after matched filter (optional)
        if isfield(params.plot, 'rxSpectrum') && params.plot.rxSpectrum && k == 1
            % 原始（匹配滤波前）
            N_fft = 2^nextpow2(length(rx_baseband));
            rx_baseband_fft = fftshift(fft(rx_baseband, N_fft));
            f_axis = linspace(-params.rf.Fs_total/2, params.rf.Fs_total/2, N_fft)/1e6;  % MHz
            spectrum_rx_baseband_dB = 20*log10(abs(rx_baseband_fft) / max(abs(rx_baseband_fft)));
        
            % 匹配滤波后
            rx_matched_fft = fftshift(fft(rx_matched, N_fft));
            spectrum_rx_matched_dB = 20*log10(abs(rx_matched_fft) / max(abs(rx_matched_fft)));
        
            % 绘制对比图
            figure;
            plot(f_axis, spectrum_rx_baseband_dB, 'b', 'LineWidth', 1.2); hold on;
            plot(f_axis, spectrum_rx_matched_dB, 'r', 'LineWidth', 1.2); hold off;
            xlabel('Frequency (MHz)');
            ylabel('Magnitude (dB)');
            title('Spectrum Before and After Matched Filter');
            legend('Before Filter', 'After Filter');
            grid on;
            xlim([-params.rf.Fs_total/2, params.rf.Fs_total/2]/1e6);
            ylim([-80 0]);
        
            % 保存图像（可选）
            if isfield(params.plot, 'save') && params.plot.save
                saveas(gcf, fullfile(params.plot.save_path, ['rx_spectrum_comparison.' params.plot.save_fmt]));
            end
        end

        rx_down = downsample(rx_matched, params.filter.sps);
        len_per_sym = params.ofdm.N_sub + params.ofdm.CP_len;
        rx_down = rx_down(1:len_per_sym*params.ofdm.numSymbols);
        rx_cp = reshape(rx_down, len_per_sym, []);
        rx_no_cp = rx_cp(params.ofdm.CP_len+1:end, :);
        rx_fft = fft(rx_no_cp, params.ofdm.N_sub, 1) / sqrt(params.ofdm.N_sub);
        rx_fft_masked = rx_fft(params.ofdm.mask, :);

        if isfield(params, 'debug') && isfield(params.debug, 'tx_symbols_active')
            ref_symbols_k = params.debug.tx_symbols_active(:,:, k);
            ref_symbols_all = [ref_symbols_all; ref_symbols_k(:)]; %#ok<AGROW>
            rx_symbols_all = [rx_symbols_all; rx_fft_masked(:)]; %#ok<AGROW>
        end
        
        rx_llr_k = qamdemod(rx_fft_masked(:), params.mod.M, 'OutputType', 'llr', 'UnitAveragePower', true);

        ptr = 1;
        for i = 1:IterAllNum
            bit_block_rx = zeros(5, params.mod.E);
            for j = 1:4
                b_subCarrier = rx_llr_k(ptr:ptr + params.ofdm.num_active_subcarriers - 1);
                for blk = 1:5
                    bit_block_rx(blk, 1+(j-1)*32:j*32) = b_subCarrier(1+(blk-1)*32:blk*32)';
                end
                ptr = ptr + params.ofdm.num_active_subcarriers;
            end
            for blk = 1:5
                b_decPolar = nrPolarDecode(bit_block_rx(blk, :)', params.mod.K + params.mod.CRCLen, params.mod.E, 8);
                b_decCrc = nrCRCDecode(b_decPolar, '24C');
                decoded_bits(info_ptr:info_ptr + params.mod.K - 1) = b_decCrc;
                info_ptr = info_ptr + params.mod.K;
            end
        end
    end

    %% Plot Receiver Constellation
    if isfield(params.plot, 'rxMD') && params.plot.rxMD
        scatterplot(rx_fft_masked(:));
        title('Receiver Constellation');
        xlabel('In-phase'); ylabel('Quadrature');
        axis square; grid on;
        if isfield(params.plot, 'save') && params.plot.save
            saveas(gcf, fullfile(params.plot.save_path, ['rx_constellation.' params.plot.save_fmt]));
        end
    end

    [evm_rms, evm_percent, evm_db, align_gain] = computeRmsEvm(ref_symbols_all, rx_symbols_all);
    rx_metrics = struct( ...
        'evm_rms', evm_rms, ...
        'evm_percent', evm_percent, ...
        'evm_db', evm_db, ...
        'align_gain_real_imag', [real(align_gain), imag(align_gain)], ...
        'num_symbols', numel(ref_symbols_all));
end


function [evm_rms, evm_percent, evm_db, align_gain] = computeRmsEvm(ref_symbols, rx_symbols)
    ref_symbols = ref_symbols(:);
    rx_symbols = rx_symbols(:);

    valid_mask = isfinite(real(ref_symbols)) & isfinite(imag(ref_symbols)) & ...
        isfinite(real(rx_symbols)) & isfinite(imag(rx_symbols));
    ref_symbols = ref_symbols(valid_mask);
    rx_symbols = rx_symbols(valid_mask);

    if isempty(ref_symbols)
        evm_rms = NaN;
        evm_percent = NaN;
        evm_db = NaN;
        align_gain = NaN;
        return;
    end

    ref_energy = sum(abs(ref_symbols).^2);
    if ref_energy <= eps
        evm_rms = NaN;
        evm_percent = NaN;
        evm_db = NaN;
        align_gain = NaN;
        return;
    end

    % Remove a common complex gain before measuring EVM so the metric
    % reflects residual waveform distortion rather than a trivial scale/phase offset.
    align_gain = (ref_symbols' * rx_symbols) / ref_energy;
    err_symbols = rx_symbols - align_gain * ref_symbols;
    evm_rms = sqrt(sum(abs(err_symbols).^2) / ref_energy);
    evm_percent = 100 * evm_rms;
    evm_db = 20 * log10(max(evm_rms, eps));
end
