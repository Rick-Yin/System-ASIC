clc; close all;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(genpath(script_dir));

config = struct();
config.MCSValues = [5 9 13]; % QPSK / 16QAM / 64QAM
config.randseed = 0;

config.filterDesignMode = "ExternalCompare";
config.filterCompareMethods = ["MIGO", "WLS", "SWLS"];
config.filterWorkspaceRoot = fullfile(repo_root, "data", "ber_coeff_workspace");
config.filterExternalJsons = defaultFilterJsons(repo_root);

config.experimentCases = buildDefaultBerExperimentCases();
config.pythonCommand = defaultPythonCommand();
config.linearExchangeRoot = fullfile(repo_root, "data", "linear_backend_exchange");
config.linearBackendEntry = fullfile(repo_root, "psrc", "ber_linear_backend.py");
config.keySNRPoints = [-5 15];
config.reportRoot = fullfile(repo_root, "report", "exp");
config.generatePaperArtifacts = true;
config.plotLegacyBERFigure = false;
config = applyRuntimeOverrides(config);

validateMcsValues(config.MCSValues);

result_files = strings(0, 1);
for mcs_idx = 1:numel(config.MCSValues)
    rng(config.randseed);

    mcs_value = config.MCSValues(mcs_idx);
    run_config = config;
    run_config.MCSValue = mcs_value;

    params_template = ConfigParams(run_config);
    params_template.info.MCSValue = mcs_value;
    params_template.info.randseed = config.randseed;
    params_template.plot.BER = logical(config.plotLegacyBERFigure);

    snr_range = params_template.iter.snr_range;
    numIter = params_template.iter.numIter;
    case_configs = params_template.experiment.cases;

    case_names = arrayfun(@(cfg) char(cfg.case_id), case_configs, 'UniformOutput', false);
    ber_curve_by_case = zeros(numel(case_configs), numel(snr_range));
    evm_curve_by_case = zeros(numel(case_configs), numel(snr_range));
    compare_results = repmat(struct( ...
        'name', '', ...
        'display_name', '', ...
        'ber_curve', [], ...
        'evm_curve', [], ...
        'filter_source', '', ...
        'linearization_mode', '', ...
        'backend_name', '', ...
        'exchange_root', '', ...
        'mcs_value', 0, ...
        'modulation_name', ''), numel(case_configs), 1);

    modulation_name = char(getModulationNameFromMCS(mcs_value));
    fprintf('\n=== Running MCS %d (%s) ===\n', mcs_value, modulation_name);

    for case_idx = 1:numel(case_configs)
        params = params_template;
        case_cfg = case_configs(case_idx);
        params.experiment.active_case = case_cfg;

        params = activateFilterForCase(params, case_cfg);
        params.info.FilterMethod = char(params.filter.active_method);
        params.info.CaseId = char(case_cfg.case_id);
        params.info.LinearizationMode = char(case_cfg.backend_mode);
        params.save.ber_curve = zeros(size(snr_range));
        params.save.evm_curve = zeros(size(snr_range));

        backend_name = "";
        exchange_root = "";

        fprintf('\nRunning BER/EVM sweep for case %s (%s + %s)\n', ...
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
                [decoded_bits, rx_metrics] = Receiver(rx_sum, params);

                rx_error_bits = sum(decoded_bits ~= info);
                ber_iter = rx_error_bits / length(info);
                params.save.ber_curve(idx) = params.save.ber_curve(idx) + ber_iter;
                params.save.evm_curve(idx) = params.save.evm_curve(idx) + rx_metrics.evm_rms;
            end
        end

        params.save.ber_curve = params.save.ber_curve / numIter;
        params.save.evm_curve = params.save.evm_curve / numIter;
        ber_curve_by_case(case_idx, :) = params.save.ber_curve;
        evm_curve_by_case(case_idx, :) = params.save.evm_curve;

        fprintf('[%s] done. BER first/last = %.5e / %.5e, EVM first/last = %.5f / %.5f\n', ...
            params.info.CaseId, params.save.ber_curve(1), params.save.ber_curve(end), ...
            params.save.evm_curve(1), params.save.evm_curve(end));

        compare_results(case_idx).name = params.info.CaseId;
        compare_results(case_idx).display_name = char(getPaperCaseDisplayName(case_cfg.case_id));
        compare_results(case_idx).ber_curve = params.save.ber_curve;
        compare_results(case_idx).evm_curve = params.save.evm_curve;
        compare_results(case_idx).filter_source = char(params.filter.active_source);
        compare_results(case_idx).linearization_mode = char(case_cfg.backend_mode);
        compare_results(case_idx).backend_name = char(backend_name);
        compare_results(case_idx).exchange_root = char(exchange_root);
        compare_results(case_idx).mcs_value = mcs_value;
        compare_results(case_idx).modulation_name = modulation_name;
    end

    if params_template.plot.BER
        plotLegacyBerCompare(snr_range, ber_curve_by_case, case_names, mcs_value);
    end

    params_save = params_template;
    params_save.info.MCSValue = mcs_value;
    params_save.info.randseed = config.randseed;
    params_save.info.modulation_name = modulation_name;
    params_save.save.compare_results = compare_results;
    params_save.save.ber_curve_by_method = ber_curve_by_case;
    params_save.save.evm_curve_by_method = evm_curve_by_case;
    params_save.save.method_names = case_names;
    params_save.save.case_configs = case_configs;
    params_save.save.key_snr_points = config.keySNRPoints;
    saveData(params_save);

    result_files(end + 1, 1) = compareResultFilePath(repo_root, mcs_value, config.randseed);
end

if config.generatePaperArtifacts
    artifact_paths = generatePaperFiguresAndTable(result_files, config.keySNRPoints, config.reportRoot);
    fprintf('\nPaper artifacts generated under %s\n', config.reportRoot);
    disp(artifact_paths);
end


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


function filter_jsons = defaultFilterJsons(repo_root)
    filter_jsons = struct( ...
        "MIGO", "", ...
        "WLS", "", ...
        "SWLS", "" ...
    );
    filter_info_root = fullfile(repo_root, "msrc", "FilterInfo");
    filter_methods = ["MIGO", "WLS", "SWLS"];

    for idx = 1:numel(filter_methods)
        method_name = filter_methods(idx);
        json_path = findFilterInfoRunSummary(filter_info_root, method_name);
        if strlength(json_path) > 0
            filter_jsons.(char(method_name)) = char(json_path);
        end
    end
end


function json_path = findFilterInfoRunSummary(filter_info_root, method_name)
    pattern = sprintf('method-%s*', lower(char(method_name)));
    matches = dir(fullfile(filter_info_root, pattern, 'run_summary.json'));
    if isempty(matches)
        json_path = "";
        return;
    end

    if numel(matches) > 1
        [~, order] = sort([matches.datenum], 'descend');
        matches = matches(order);
    end
    json_path = string(fullfile(matches(1).folder, matches(1).name));
end


function validateMcsValues(mcs_values)
    if isempty(mcs_values)
        error('MCSValues must not be empty.');
    end
    for idx = 1:numel(mcs_values)
        getMCSValue(mcs_values(idx));
    end
end


function plotLegacyBerCompare(snr_range, ber_curve_by_case, case_names, mcs_value)
    figure;
    hold on;
    plot_styles = {'o-', 's-', '^-', 'd-', 'x-', '+-', 'v-', 'p-'};
    for case_idx = 1:numel(case_names)
        style_idx = mod(case_idx - 1, numel(plot_styles)) + 1;
        semilogy(snr_range, ber_curve_by_case(case_idx, :), ...
            plot_styles{style_idx}, 'LineWidth', 2);
    end
    hold off;
    xlabel('SNR (dB)');
    ylabel('Bit Error Rate (BER)');
    title(sprintf('BER vs SNR for MCS %d', mcs_value));
    grid on;
    legend(case_names, 'Location', 'southwest', 'Interpreter', 'none');
end


function result_path = compareResultFilePath(repo_root, mcs_value, randseed)
    result_path = string(fullfile( ...
        repo_root, ...
        'data', ...
        'BER-SNR', ...
        sprintf('ber_compare_MCS_%d_seed_%d.mat', mcs_value, randseed)));
end


function config = applyRuntimeOverrides(config)
    config.MCSValues = parseNumericEnvList('SYSTEM_ASIC_MCS_VALUES', config.MCSValues);
    config.keySNRPoints = parseNumericEnvList('SYSTEM_ASIC_KEY_SNR_POINTS', config.keySNRPoints);
    case_id_override = parseStringEnvList('SYSTEM_ASIC_CASE_IDS');
    if ~isempty(case_id_override)
        config.experimentCases = filterCasesById(config.experimentCases, case_id_override);
    end

    snr_override = parseNumericEnvList('SYSTEM_ASIC_SNR_RANGE', []);
    if ~isempty(snr_override)
        config.SNRRange = snr_override;
    end

    num_iter_override = getenv('SYSTEM_ASIC_NUM_ITER');
    if ~isempty(strtrim(num_iter_override))
        config.NumIter = str2double(num_iter_override);
    end

    report_root_override = getenv('SYSTEM_ASIC_REPORT_ROOT');
    if ~isempty(strtrim(report_root_override))
        config.reportRoot = report_root_override;
    end

    generate_artifacts_override = getenv('SYSTEM_ASIC_GENERATE_PAPER_ARTIFACTS');
    if ~isempty(strtrim(generate_artifacts_override))
        config.generatePaperArtifacts = parseLogicalEnv(generate_artifacts_override);
    end

    legacy_plot_override = getenv('SYSTEM_ASIC_PLOT_LEGACY_BER_FIGURE');
    if ~isempty(strtrim(legacy_plot_override))
        config.plotLegacyBERFigure = parseLogicalEnv(legacy_plot_override);
    end
end


function values = parseNumericEnvList(env_name, default_value)
    raw_value = getenv(env_name);
    if isempty(strtrim(raw_value))
        values = default_value;
        return;
    end

    normalized = regexprep(strtrim(raw_value), '[,\s;:]+', ' ');
    values = sscanf(normalized, '%f').';
    if isempty(values)
        error('Environment variable %s did not contain any numeric values.', env_name);
    end
end


function values = parseStringEnvList(env_name)
    raw_value = getenv(env_name);
    if isempty(strtrim(raw_value))
        values = strings(0, 1);
        return;
    end

    normalized = regexprep(strtrim(raw_value), '[,\s;:]+', ' ');
    tokens = strsplit(strtrim(normalized), ' ');
    tokens = tokens(~cellfun('isempty', tokens));
    values = string(tokens(:));
end


function filtered_cases = filterCasesById(case_configs, case_ids)
    keep_mask = false(size(case_configs));
    for idx = 1:numel(case_configs)
        keep_mask(idx) = any(strcmp(string(case_configs(idx).case_id), case_ids));
    end

    filtered_cases = case_configs(keep_mask);
    if isempty(filtered_cases)
        error('SYSTEM_ASIC_CASE_IDS did not match any configured experiment case.');
    end
end


function flag = parseLogicalEnv(raw_value)
    token = lower(strtrim(string(raw_value)));
    switch token
        case {"1", "true", "yes", "on"}
            flag = true;
        case {"0", "false", "no", "off"}
            flag = false;
        otherwise
            error('Unsupported logical environment value: %s', raw_value);
    end
end
