function [] = saveData(params)
    if ~isfield(params, 'save') || ~isfield(params.save, 'enable') || ~params.save.enable
        return;
    end

    save_root = params.save.save_root;
    method_tag = "SRRC";
    if isfield(params, 'info') && isfield(params.info, 'FilterMethod')
        method_tag = string(params.info.FilterMethod);
    end

    if isfield(params.save, 'compare_results') && ~isempty(params.save.compare_results)
        saveCompareResults(params, save_root);
        return;
    end

    saveSingleMethodResults(params, save_root, method_tag);
end


function saveCompareResults(params, save_root)
    save_root_ber = fullfile(save_root, "BER-SNR");
    if ~exist(save_root_ber, 'dir')
        mkdir(save_root_ber);
    end

    ber_filename = sprintf("ber_compare_MCS_%d_seed_%d.mat", ...
        params.info.MCSValue, params.info.randseed);
    ber_file = fullfile(save_root_ber, ber_filename);

    payload = struct();
    payload.snr_range = params.iter.snr_range;
    payload.ber_curve_by_method = params.save.ber_curve_by_method;
    payload.method_names = params.save.method_names;
    payload.case_ids = params.save.method_names;
    payload.compare_results = params.save.compare_results;
    payload.mcs_value = params.info.MCSValue;
    if isfield(params.info, 'modulation_name')
        payload.modulation_name = params.info.modulation_name;
    end
    if isfield(params.save, 'evm_curve_by_method')
        payload.evm_curve_by_method = params.save.evm_curve_by_method;
    end
    if isfield(params.save, 'case_configs')
        payload.case_configs = params.save.case_configs;
    end
    if isfield(params.save, 'key_snr_points')
        payload.key_snr_points = params.save.key_snr_points;
    end

    save(ber_file, '-struct', 'payload', '-v7.3');
end


function saveSingleMethodResults(params, save_root, method_tag)
    save_root_tx = fullfile(save_root, "HPA", char(method_tag));
    seed_tag = params.info.randseed;
    mcs_tag = params.info.MCSValue;
    if ~exist(save_root_tx, 'dir')
        mkdir(save_root_tx);
    end

    if isfield(params.save, 'tx_sum_all') && isfield(params.save, 'tx_sig_all')
        for i = 1:length(params.iter.snr_range)
            snr_tag = params.iter.snr_range(i);
            save_dir_tx = fullfile(save_root_tx, ...
                sprintf('MCS_%d_SNR_%d_Seed_%d', mcs_tag, snr_tag, seed_tag));
            if ~exist(save_dir_tx, 'dir')
                mkdir(save_dir_tx);
            end

            tx_sum = params.save.tx_sum_all(:, :, i);
            tx_sig = params.save.tx_sig_all(:, :, i);
            tx_sum_save = [real(tx_sum(:)), imag(tx_sum(:))];
            tx_sig_save = [real(tx_sig(:)), imag(tx_sig(:))];

            writematrix(tx_sum_save, fullfile(save_dir_tx, "input.csv"));
            writematrix(tx_sig_save, fullfile(save_dir_tx, "output.csv"));
        end
    end

    save_root_ber = fullfile(save_root, "BER-SNR");
    if ~exist(save_root_ber, 'dir')
        mkdir(save_root_ber);
    end

    ber_filename = sprintf("ber_curve_%s_MCS_%d_seed_%d.mat", ...
        lower(char(method_tag)), params.info.MCSValue, params.info.randseed);
    ber_file = fullfile(save_root_ber, ber_filename);

    payload = struct();
    payload.snr_range = params.iter.snr_range;
    payload.ber_curve = params.save.ber_curve;
    if isfield(params.save, 'evm_curve')
        payload.evm_curve = params.save.evm_curve;
    end

    save(ber_file, '-struct', 'payload', '-v7.3');
end
