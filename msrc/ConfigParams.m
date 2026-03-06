function params = ConfigParams(config)
    %% Iteration config setting
    params.iter.snr_range = -5:1:24;
    params.iter.numIter = 1;

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

    if strcmpi(params.filter.design_mode, "ExternalCompare")
        compare_methods = string(params.filter.compare_methods);
        for method_idx = 1:numel(compare_methods)
            method_name = upper(char(compare_methods(method_idx)));
            if ~isfield(params.filter.external_json, method_name)
                error('Missing JSON path for filter method %s.', method_name);
            end
            params.filter.external_bank.(method_name) = loadFilterFromRunSummary( ...
                params.filter.external_json.(method_name), ...
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
    switch config.CFRType
        case "NoCFR"
            % No CFR
            params.CFR.Method = 0;
        case "HC"
            % Hard clipper
            params.CFR.Method = 1;
            params.CFR.ClipMax = 0.12;
        case "CAF"
            % Crest Factor Reduction Filter
            params.CFR.Method = 2;
            params.CFR.ClipFactor = 0.9;
    end

    %% DPD Method and params
    params.DPD = struct();
    params.DPD.symNum = 15000;
    switch config.DPDType
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
    end

    %% PA parameters
    params.PA.Gain = 1;
    params.PA.TargetPeakAmp = 0.8;

    %% Save data
    params.save.enable = true;
    params.save.save_root = 'data/';
end
