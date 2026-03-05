clc; close all;

CFRType = ["NoCFR","HC","CAF"];
DPDType = ["NoDPD","LUT"];

config.CFRType = CFRType(1);
config.DPDType = DPDType(1);
config.MCSValue = 13; % QPSK:5 16QAM:9 64QAM:13
config.randseed = 0;

rng(config.randseed);

params = ConfigParams(config);
params.info.MCSValue = config.MCSValue;
params.info.randseed = config.randseed;

% Iteration config setting
snr_range = params.iter.snr_range;
numIter = params.iter.numIter;
params.save.ber_curve = zeros(size(snr_range));

for idx = 1:length(snr_range)
    SNR_dB = snr_range(idx);
    ber_total = 0;
    for iter = 1:numIter
        params.info.SNRidx = idx;
        params.info.IterNum = iter;

        [tx_sum, info, params] = Transmitter(params);

        rx_sum = Channel(tx_sum, SNR_dB, params);

        decoded_bits = Receiver(rx_sum, params);

        rx_error_bits = sum(decoded_bits ~= info);
        ber_iter = rx_error_bits / length(info);
        ber_total = ber_total + ber_iter;
    end
    params.save.ber_curve(idx) = ber_total / numIter;
    fprintf('SNR = %2d dB -> BER = %.5e\n', SNR_dB, params.save.ber_curve(idx));
end

if params.plot.BER
    snr_linear = 10.^(snr_range / 10);
    
    figure;
    semilogy(snr_range, params.save.ber_curve, 'bo-', 'LineWidth', 2); hold on;
    xlabel('SNR (dB)'); ylabel('Bit Error Rate (BER)');
    title('BER vs SNR for Starlink-like Aggregated OFDM System');
    grid on; legend('Simulated BER');
end

saveData(params);