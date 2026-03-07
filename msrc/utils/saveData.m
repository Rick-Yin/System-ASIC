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

    snr_range = params.iter.snr_range;
    ber_curve_by_method = params.save.ber_curve_by_method;
    method_names = params.save.method_names;
    compare_results = params.save.compare_results;
    case_ids = method_names;

    ber_filename = sprintf("ber_compare_MCS_%d_seed_%d.mat", ...
        params.info.MCSValue, params.info.randseed);
    ber_file = fullfile(save_root_ber, ber_filename);
    if isfield(params.save, 'case_configs')
        case_configs = params.save.case_configs;
        save(ber_file, 'snr_range', 'ber_curve_by_method', ...
            'method_names', 'case_ids', 'compare_results', 'case_configs', '-v7.3');
    else
        save(ber_file, 'snr_range', 'ber_curve_by_method', ...
            'method_names', 'case_ids', 'compare_results', '-v7.3');
    end
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

    snr_range = params.iter.snr_range;
    ber_curve = params.save.ber_curve;
    ber_filename = sprintf("ber_curve_%s_MCS_%d_seed_%d.mat", ...
        lower(char(method_tag)), params.info.MCSValue, params.info.randseed);
    ber_file = fullfile(save_root_ber, ber_filename);
    save(ber_file, 'snr_range', 'ber_curve', '-v7.3');
end
