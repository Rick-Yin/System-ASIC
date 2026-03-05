function [tx_sig, info, params] = Transmitter(params)
    % SLB OFDM System: Transmitter Module
    % This function generates the transmitted signal for a multi-carrier OFDM system.

    bits_per_carrier = params.ofdm.num_active_subcarriers * params.ofdm.numSymbols * params.mod.bits_per_sym;
    IterAllNum = params.rf.numCarriers * params.ofdm.numSymbols * params.mod.bits_per_sym / 4;
    mod_bits = zeros(bits_per_carrier * params.rf.numCarriers, 1);
    info = zeros((params.mod.K * 5) * IterAllNum, 1);
    ptr = 1; info_ptr = 1;

    %% Bit Level Processing
    for i = 1:IterAllNum
        bit_block = zeros(5, params.mod.E);
        for blk = 1:5
            InfoBits = randi([0 1], params.mod.K, 1);
            info(info_ptr: info_ptr + params.mod.K - 1) = InfoBits;
            info_ptr = info_ptr + params.mod.K;
            b_crc = nrCRCEncode(InfoBits, '24C');
            b_enc = nrPolarEncode(b_crc, params.mod.E);
            bit_block(blk, :) = b_enc;
        end
        bit_subblocks = reshape(bit_block(:, 1:128), 5, 32, 4);  % [block, bits, subcarrier]
        b_subCarrier_all = reshape(permute(bit_subblocks, [2, 1, 3]), [], 1);  % reshape to [160*4 × 1]
        mod_bits(ptr:ptr + length(b_subCarrier_all) - 1) = b_subCarrier_all;
        ptr = ptr + length(b_subCarrier_all);
    end
    symbols = qammod(mod_bits, params.mod.M, 'InputType', 'bit', 'UnitAveragePower', true);

    %% Symbol Level Processing
    tx_carriers = zeros((params.ofdm.N_sub + params.ofdm.CP_len) * params.ofdm.numSymbols * params.filter.sps, params.rf.numCarriers);
    for k = 1:params.rf.numCarriers
        sym_offset = (k-1)*bits_per_carrier/params.mod.bits_per_sym + 1;
        sym_range = sym_offset:(sym_offset + bits_per_carrier/params.mod.bits_per_sym - 1);
        symbols_k_active_flat = symbols(sym_range);
        symbols_k_active = reshape(symbols_k_active_flat, params.ofdm.num_active_subcarriers, []);
        symbols_k = zeros(params.ofdm.N_sub, params.ofdm.numSymbols);
        symbols_k(params.ofdm.mask, :) = symbols_k_active;
        ofdm_k = ifft(symbols_k, params.ofdm.N_sub, 1)*sqrt(params.ofdm.N_sub);
        ofdm_cp = [ofdm_k(end-params.ofdm.CP_len+1:end, :); ofdm_k];
        tx_serial = ofdm_cp(:); % Flatten to serial stream
        tx_upsampled = upsample(tx_serial, params.filter.sps);
        tx_filt = conv(tx_upsampled, params.filter.rcFilter, 'same');
        t = (0:length(tx_filt)-1).' / params.rf.Fs_total;
        tx_carriers(:, k) = tx_filt .* exp(1j*2*pi*params.rf.f_center(k)*t);

        % debug data
        params.debug.symbols_k(:,:, k) = symbols_k;
        params.debug.ofdm_k(:,:, k) = ofdm_k;
        params.debug.ofdm_cp(:,:, k) = ofdm_cp;
        params.debug.tx_serial(:, k) = tx_serial;
        params.debug.tx_upsampled(:, k) = tx_upsampled;
        params.debug.tx_filt(:, k) = tx_filt;
        params.debug.tx_carriers(:, k) = tx_carriers(:, k);
    end
    tx_sum = sum(tx_carriers, 2);
    tx_sum = params.PA.TargetPeakAmp * tx_sum / sqrt(max(abs(tx_sum).^2));
    %% Digital Front-End Processing

    % CFR Algorithm
    tx_CFR = applyCFR(tx_sum, params);

    % DPD Algorithm
    tx_DPD = applyDPD(tx_CFR, params);

    % PA Model
    tx_sig = PA(tx_DPD, params);

    %% debug data
    params.debug.tx_sig = tx_sig;

    %% save transimit data
    params.save.tx_sum_all(:, params.info.IterNum, params.info.SNRidx) = tx_sum;
    params.save.tx_sig_all(:, params.info.IterNum, params.info.SNRidx) = tx_sig;

    %% Plot data
    if isfield(params.plot, 'txMD') && params.plot.txMD
        scatterplot(symbols);
        title('Transmitter Constellation');
        xlabel('In-phase'); ylabel('Quadrature');
        axis square; grid on;
        if isfield(params.plot, 'save') && params.plot.save
            saveas(gcf, fullfile(params.plot.save_path, ['tx_constellation.' params.plot.save_fmt]));
        end
    end

    if isfield(params.plot, 'txSpectrum') && params.plot.txSpectrum
        N_fft = 2^nextpow2(length(tx_sum));
        tx_fft = fftshift(fft(tx_sum, N_fft));
        f_axis = linspace(-params.rf.Fs_total/2, params.rf.Fs_total/2, N_fft)/1e6;  % MHz

        spectrum_dB = 20*log10(abs(tx_fft) / max(abs(tx_fft)));

        figure;
        plot(f_axis, spectrum_dB, 'b', 'LineWidth', 1.5);
        xlabel('Frequency (MHz)');
        ylabel('Magnitude (dB)');
        title('Transmitted Signal Spectrum');
        grid on;
        xlim([-params.rf.Fs_total/2, params.rf.Fs_total/2]/1e6);
        ylim([-80 0]); 

        if isfield(params.plot, 'save') && params.plot.save
            saveas(gcf, fullfile(params.plot.save_path, ['tx_spectrum.' params.plot.save_fmt]));
        end
    end

end
