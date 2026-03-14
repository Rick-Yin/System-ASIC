function params = ConfigParams(config)
    repo_root = fileparts(fileparts(mfilename('fullpath')));
    params.repo.root = repo_root;
    cfr_type = normalizeConfigMode(config, 'CFRType', "NoCFR");
    dpd_type = normalizeConfigMode(config, 'DPDType', "NoDPD");

    %% Iteration config setting
    params.iter.snr_range = -5:1:24;
    params.iter.numIter = 1;
    if isfield(config, 'SNRRange') && ~isempty(config.SNRRange)
        params.iter.snr_range = double(config.SNRRange(:)');
    end
    if isfield(config, 'NumIter') && ~isempty(config.NumIter)
        params.iter.numIter = double(config.NumIter);
    end

    %% 时间结构
    params.time.Ts = 1 / (30.72e6);
    params.time.T_OFDM = 64 * params.time.Ts;
    params.time.T_cp = 5 * params.time.Ts;
    params.time.T_sym = params.time.T_cp + params.time.T_OFDM;
    params.time.T_radio_frame = 640 * params.time.Ts;
    params.time.N_sym_per_frame = 8;
    params.time.T_superframe = 1e-3;
    params.time.N_frame_per_superframe = 48;

    %% OFDM结构
    params.ofdm.N_sub = 256;
    params.ofdm.CP_len = 5;
    params.ofdm.numSymbols = params.time.N_sym_per_frame * params.time.N_frame_per_superframe;
    params.ofdm.mask = false(params.ofdm.N_sub, 1);
    params.ofdm.mask(1:80) = true;
    params.ofdm.mask(82:161) = true;
    params.ofdm.num_active_subcarriers = sum(params.ofdm.mask);

    %% 载波聚合
    params.rf.numCarriers = 10;
    params.rf.B_sub = 20e6;
    params.rf.Fs = 30.72e6;
    params.rf.Fs_total = 200e6;
    params.rf.spacing = 19.92e6;
    params.rf.f_center = (-4.5:1:4.5) * params.rf.spacing;

    %% 滤波参数
    params.filter.sps = 16;
    params.filter.span = 10;
    params.filter.rolloff = 0.25;
    params.filter.rcFilter = rcosdesign(params.filter.rolloff, params.filter.span, params.filter.sps, 'sqrt');
    params.filter.expected_len = params.filter.span * params.filter.sps + 1;
    params.filter.design_mode = "SRRC";
    params.filter.compare_methods = "SRRC";
    params.filter.active_method = "SRRC";
    params.filter.active_coeffs = params.filter.rcFilter(:);
    params.filter.active_source = "rcosdesign";
    params.filter.external_json = struct("MIGO", "", "WLS", "", "SWLS", "");
    params.filter.external_bank = struct();
    params.filter.workspace_root = fullfile(repo_root, 'data', 'ber_coeff_workspace');

    if isfield(config, 'filterDesignMode')
        params.filter.design_mode = string(config.filterDesignMode);
    end
    if isfield(config, 'filterCompareMethods')
        params.filter.compare_methods = string(config.filterCompareMethods);
    elseif strcmpi(params.filter.design_mode, "ExternalCompare")
        params.filter.compare_methods = ["MIGO", "WLS", "SWLS"];
    end
    if isfield(config, 'filterExternalJsons')
        params.filter.external_json = config.filterExternalJsons;
    end
    if isfield(config, 'filterWorkspaceRoot')
        params.filter.workspace_root = char(string(config.filterWorkspaceRoot));
    end

    if strcmpi(params.filter.design_mode, "ExternalCompare")
        compare_methods = string(params.filter.compare_methods);
        for method_idx = 1:numel(compare_methods)
            method_name = upper(char(compare_methods(method_idx)));
            if ~isfield(params.filter.external_json, method_name)
                error('Missing JSON path for filter method %s.', method_name);
            end
            explicit_json = string(params.filter.external_json.(method_name));
            resolved_json = resolveWorkspaceJsonPath(method_name, explicit_json, params.filter.workspace_root);
            params.filter.external_json.(method_name) = char(resolved_json);
            params.filter.external_bank.(method_name) = loadFilterFromRunSummary( ...
                resolved_json, ...
                params.filter.expected_len);
        end
    end

    %% 编码调制参数
    [params.mod.bits_per_sym, params.mod.R] = getMCSValue(config.MCSValue);
    params.mod.M = 2 ^ params.mod.bits_per_sym;
    params.mod.E = 128;
    params.mod.CRCLen = 24;
    params.mod.K = ceil(params.mod.E * params.mod.R - params.mod.CRCLen);

    %% 信道参数
    params.channel.type = 'awgn';

    %% 绘图参数
    params.plot.BER = false;
    params.plot.tx = false;
    params.plot.rx = false;
    params.plot.CFR = false;
    params.plot.DPD = false;
    params.plot.txMD  = false;
    params.plot.rxMD  = false;
    params.plot.txSpectrum = false;
    params.plot.rxSpectrum = false;
    params.plot.AMAM  = false;
    params.plot.AMPM  = false;
    params.plot.PoutPin = false;
    params.plot.ACLR = false;
    params.plot.save = false;
    params.plot.save_path = 'pics/';
    params.plot.save_fmt = 'png';

    %% CFR 算法参数
    % CFR_Params.Method 0: No CFR 1: HF 2: CAF ...
    switch cfr_type
        case "NoCFR"
            % No CFR
            params.CFR.Method = 0;
            params.CFR.ClipMax = 1.0;
        case "HC"
            % Hard clipper
            params.CFR.Method = 1;
            params.CFR.ClipMax = 0.12;
        case "CAF"
            % Crest Factor Reduction Filter
            params.CFR.Method = 2;
            params.CFR.ClipFactor = 0.9;
            params.CFR.ClipMax = 0.12;
        otherwise
            error('Unsupported CFRType: %s', cfr_type);
    end

    %% DPD Method and params
    params.DPD = struct();
    params.DPD.symNum = 15000;
    switch dpd_type
        case "NoDPD"
            % No DPD
            params.DPD.Method = 0;
        case "LUT"
            % LUT DPD
            params.DPD.Method = 1;
        case "DynaLUT"
            params.DPD.Method = 2;
        case "Volterra"
            params.DPD.Method = 3;
        case "MP"
            params.DPD.Method = 4;
        otherwise
            error('Unsupported DPDType: %s', dpd_type);
    end

    %% PA parameters
    params.PA.Gain = 1;
    params.PA.TargetPeakAmp = 0.8;

    %% Experiment matrix
    params.experiment = struct();
    params.experiment.cases = buildDefaultBerExperimentCases();
    params.experiment.active_case = struct();
    if isfield(config, 'experimentCases')
        params.experiment.cases = config.experimentCases;
    end

    %% External linearization backend
    params.linearization = struct();
    params.linearization.backend = "python_file_exchange";
    params.linearization.python_cmd = defaultPythonCommand();
    params.linearization.backend_entry = fullfile(repo_root, 'psrc', 'ber_linear_backend.py');
    params.linearization.exchange_root = fullfile(repo_root, 'data', 'linear_backend_exchange');
    params.linearization.model_manifest = fullfile(repo_root, 'vsrc', 'rom', 'manifest.json');
    params.linearization.model_bin_dir = fullfile(repo_root, 'vsrc', 'rom', 'bin');
    params.linearization.hc_clip_max = 0.12;
    params.linearization.dpd_iterations = 4;
    params.linearization.dpd_step = 0.75;
    params.linearization.volterra_coeffs = [ ...
        1.0513 + 0.0904i, -0.0680 - 0.0023i,  0.0289 + 0.0054i, ...
        0.0542 - 0.2900i,  0.2234 + 0.2317i, -0.0621 - 0.0932i, ...
       -0.9657 - 0.7028i, -0.2451 - 0.3735i,  0.1229 + 0.1508i];
    if isfield(config, 'pythonCommand')
        params.linearization.python_cmd = string(config.pythonCommand);
    end
    if isfield(config, 'linearBackendEntry')
        params.linearization.backend_entry = char(string(config.linearBackendEntry));
    end
    if isfield(config, 'linearExchangeRoot')
        params.linearization.exchange_root = char(string(config.linearExchangeRoot));
    end
    if isfield(config, 'linearizationHCClipMax')
        params.linearization.hc_clip_max = double(config.linearizationHCClipMax);
    elseif cfr_type == "HC" || cfr_type == "CAF"
        params.linearization.hc_clip_max = params.CFR.ClipMax;
    end
    if isfield(config, 'linearizationDPDIterations')
        params.linearization.dpd_iterations = double(config.linearizationDPDIterations);
    end
    if isfield(config, 'linearizationDPDStep')
        params.linearization.dpd_step = double(config.linearizationDPDStep);
    end

    %% Save data
    params.save.enable = true;
    params.save.save_root = fullfile(repo_root, 'data');
end


function resolved_path = resolveWorkspaceJsonPath(method_name, explicit_path, workspace_root)
    if strlength(strtrim(explicit_path)) > 0
        resolved_path = explicit_path;
        return;
    end

    candidates = [ ...
        string(fullfile(workspace_root, upper(method_name), 'run_summary.json')), ...
        string(fullfile(workspace_root, lower(method_name), 'run_summary.json')), ...
        string(fullfile(workspace_root, method_name, 'run_summary.json')) ...
    ];

    for idx = 1:numel(candidates)
        if exist(candidates(idx), 'file') == 2
            resolved_path = candidates(idx);
            return;
        end
    end

    error(['Missing run_summary.json for filter method %s. ', ...
        'Expected explicit path or workspace layout %s/<METHOD>/run_summary.json.'], ...
        method_name, workspace_root);
end


function python_cmd = defaultPythonCommand()
    if ispc
        python_cmd = "python";
    else
        python_cmd = "python3";
    end
end


function mode_value = normalizeConfigMode(config, field_name, default_value)
    if isfield(config, field_name) && strlength(strtrim(string(config.(field_name)))) > 0
        mode_value = string(config.(field_name));
    else
        mode_value = string(default_value);
    end
end
