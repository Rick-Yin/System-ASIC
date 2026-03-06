clc; close all;
addpath(genpath(fileparts(mfilename('fullpath'))));

CFRType = ["NoCFR", "HC", "CAF"];
DPDType = ["NoDPD", "LUT"];

config.CFRType = CFRType(1);
config.DPDType = DPDType(1);
config.MCSValue = 13; % QPSK:5 16QAM:9 64QAM:13
config.randseed = 0;
config.filterDesignMode = "ExternalCompare";
config.filterCompareMethods = ["MIGO", "WLS", "SWLS"];
config.filterExternalJsons = struct( ...
    "MIGO", "", ...
    "WLS", "", ...
    "SWLS", "" ...
);

rng(config.randseed);

params_template = ConfigParams(config);
params_template.info.MCSValue = config.MCSValue;
params_template.info.randseed = config.randseed;
params_template.plot.BER = true;

snr_range = params_template.iter.snr_range;
numIter = params_template.iter.numIter;

if strcmpi(params_template.filter.design_mode, "ExternalCompare")
    method_names = cellstr(string(params_template.filter.compare_methods));
else
    method_names = {char(params_template.filter.active_method)};
end

ber_curve_by_method = zeros(numel(method_names), numel(snr_range));
compare_results = repmat(struct( ...
    'name', '', ...
    'ber_curve', [], ...
    'filter_source', ''), numel(method_names), 1);

for method_idx = 1:numel(method_names)
    params = params_template;
    method_name = upper(method_names{method_idx});

    if strcmpi(params.filter.design_mode, "ExternalCompare")
        params.filter.active_method = string(method_name);
        params.filter.active_coeffs = params.filter.external_bank.(method_name).coeffs;
        params.filter.active_source = params.filter.external_bank.(method_name).source_path;
    else
        params.filter.active_method = "SRRC";
        params.filter.active_coeffs = params.filter.rcFilter(:);
        params.filter.active_source = "ConfigParams.m";
    end

    params.info.FilterMethod = char(params.filter.active_method);
    params.save.ber_curve = zeros(size(snr_range));

    fprintf('\nRunning BER sweep for %s\n', params.info.FilterMethod);
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
        fprintf('[%s] SNR = %2d dB -> BER = %.5e\n', ...
            params.info.FilterMethod, SNR_dB, params.save.ber_curve(idx));
    end

    ber_curve_by_method(method_idx, :) = params.save.ber_curve;
    compare_results(method_idx).name = params.info.FilterMethod;
    compare_results(method_idx).ber_curve = params.save.ber_curve;
    compare_results(method_idx).filter_source = char(params.filter.active_source);
end

if params_template.plot.BER
    figure;
    hold on;
    plot_styles = {'o-', 's-', '^-', 'd-'};
    for method_idx = 1:numel(method_names)
        style_idx = mod(method_idx - 1, numel(plot_styles)) + 1;
        semilogy(snr_range, ber_curve_by_method(method_idx, :), ...
            plot_styles{style_idx}, 'LineWidth', 2);
    end
    hold off;
    xlabel('SNR (dB)');
    ylabel('Bit Error Rate (BER)');
    title('BER vs SNR for External FIR Comparison');
    grid on;
    legend(method_names, 'Location', 'southwest');
end

params_save = params_template;
params_save.save.compare_results = compare_results;
params_save.save.ber_curve_by_method = ber_curve_by_method;
params_save.save.method_names = method_names;
saveData(params_save);
