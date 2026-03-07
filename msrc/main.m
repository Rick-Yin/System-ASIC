clc; close all;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(genpath(script_dir));

config = struct();
config.MCSValue = 13; % QPSK:5 16QAM:9 64QAM:13
config.randseed = 0;

config.filterDesignMode = "ExternalCompare";
config.filterCompareMethods = ["MIGO", "WLS", "SWLS"];
config.filterWorkspaceRoot = fullfile(repo_root, "data", "ber_coeff_workspace");
config.filterExternalJsons = struct( ...
    "MIGO", "", ...
    "WLS", "", ...
    "SWLS", "" ...
);

config.experimentCases = buildDefaultBerExperimentCases();
config.pythonCommand = defaultPythonCommand();
config.linearExchangeRoot = fullfile(repo_root, "data", "linear_backend_exchange");
config.linearBackendEntry = fullfile(repo_root, "psrc", "ber_linear_backend.py");

rng(config.randseed);

params_template = ConfigParams(config);
params_template.info.MCSValue = config.MCSValue;
params_template.info.randseed = config.randseed;
params_template.plot.BER = true;

snr_range = params_template.iter.snr_range;
numIter = params_template.iter.numIter;
case_configs = params_template.experiment.cases;

case_names = arrayfun(@(cfg) char(cfg.case_id), case_configs, 'UniformOutput', false);
ber_curve_by_case = zeros(numel(case_configs), numel(snr_range));
compare_results = repmat(struct( ...
    'name', '', ...
    'ber_curve', [], ...
    'filter_source', '', ...
    'linearization_mode', '', ...
    'backend_name', '', ...
    'exchange_root', ''), numel(case_configs), 1);

for case_idx = 1:numel(case_configs)
    params = params_template;
    case_cfg = case_configs(case_idx);
    params.experiment.active_case = case_cfg;

    params = activateFilterForCase(params, case_cfg);
    params.info.FilterMethod = char(params.filter.active_method);
    params.info.CaseId = char(case_cfg.case_id);
    params.info.LinearizationMode = char(case_cfg.backend_mode);
    params.save.ber_curve = zeros(size(snr_range));

    backend_name = "";
    exchange_root = "";

    fprintf('\nRunning BER sweep for case %s (%s + %s)\n', ...
        params.info.CaseId, params.info.FilterMethod, params.info.LinearizationMode);

    for iter = 1:numIter
        params.info.IterNum = iter;

        [tx_sum, info, params] = Transmitter(params);
        [tx_lin, backend_meta, params] = applyLinearizationBackend(tx_sum, params);
        tx_sig = PA(tx_lin, params);

        if isfield(backend_meta, 'backend_name')
            backend_name = string(backend_meta.backend_name);
        else
            backend_name = string(case_cfg.backend_mode);
        end
        if isfield(params.linearization, 'last_exchange_dir')
            exchange_root = string(params.linearization.last_exchange_dir);
        end

        for idx = 1:length(snr_range)
            SNR_dB = snr_range(idx);
            params.info.SNRidx = idx;

            rx_sum = Channel(tx_sig, SNR_dB, params);
            decoded_bits = Receiver(rx_sum, params);

            rx_error_bits = sum(decoded_bits ~= info);
            ber_iter = rx_error_bits / length(info);
            params.save.ber_curve(idx) = params.save.ber_curve(idx) + ber_iter;
        end
    end

    params.save.ber_curve = params.save.ber_curve / numIter;
    ber_curve_by_case(case_idx, :) = params.save.ber_curve;

    fprintf('[%s] done. BER curve first/last = %.5e / %.5e\n', ...
        params.info.CaseId, params.save.ber_curve(1), params.save.ber_curve(end));

    compare_results(case_idx).name = params.info.CaseId;
    compare_results(case_idx).ber_curve = params.save.ber_curve;
    compare_results(case_idx).filter_source = char(params.filter.active_source);
    compare_results(case_idx).linearization_mode = char(case_cfg.backend_mode);
    compare_results(case_idx).backend_name = char(backend_name);
    compare_results(case_idx).exchange_root = char(exchange_root);
end

if params_template.plot.BER
    figure;
    hold on;
    plot_styles = {'o-', 's-', '^-', 'd-', 'x-', '+-', 'v-'};
    for case_idx = 1:numel(case_configs)
        style_idx = mod(case_idx - 1, numel(plot_styles)) + 1;
        semilogy(snr_range, ber_curve_by_case(case_idx, :), ...
            plot_styles{style_idx}, 'LineWidth', 2);
    end
    hold off;
    xlabel('SNR (dB)');
    ylabel('Bit Error Rate (BER)');
    title('BER vs SNR for Filter + Linearization Cases');
    grid on;
    legend(case_names, 'Location', 'southwest', 'Interpreter', 'none');
end

params_save = params_template;
params_save.info.MCSValue = config.MCSValue;
params_save.info.randseed = config.randseed;
params_save.save.compare_results = compare_results;
params_save.save.ber_curve_by_method = ber_curve_by_case;
params_save.save.method_names = case_names;
params_save.save.case_configs = case_configs;
saveData(params_save);


function params = activateFilterForCase(params, case_cfg)
    filter_method = upper(string(case_cfg.filter_method));
    switch filter_method
        case "SRRC"
            params.filter.active_method = "SRRC";
            params.filter.active_coeffs = params.filter.rcFilter(:);
            params.filter.active_source = "rcosdesign";
        otherwise
            if ~strcmpi(params.filter.design_mode, "ExternalCompare")
                error('Filter method %s requires ExternalCompare mode.', filter_method);
            end
            if ~isfield(params.filter.external_bank, filter_method)
                error('Filter method %s not loaded in external_bank.', filter_method);
            end
            params.filter.active_method = filter_method;
            params.filter.active_coeffs = params.filter.external_bank.(filter_method).coeffs;
            params.filter.active_source = params.filter.external_bank.(filter_method).source_path;
    end
end


function python_cmd = defaultPythonCommand()
    if ispc
        python_cmd = "python";
    else
        python_cmd = "python3";
    end
end
