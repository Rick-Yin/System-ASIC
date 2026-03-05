function [] = saveData(params)
    % saveData(params)
    if isfield(params, 'save') && isfield(params.save, 'enable') && params.save.enable
        save_root = params.save.save_root;

        % 1. save the tx data before and after only PA W.O. DPD and CFR
        save_root_tx = fullfile(save_root, "HPA");
        seed_tag = params.info.randseed; % Assuming seed_tag is derived from params
        mcs_tag = params.info.MCSValue; % Assuming mcs_tag is derived from params
        if ~exist(save_root_tx, 'dir')
            mkdir(save_root_tx);
        end
        for i = 1:length(params.iter.snr_range)
            snr_tag = params.iter.snr_range(i); % Current SNR value
            save_dir_tx = fullfile(save_root_tx, sprintf('MCS_%d_SNR_%d_Seed_%d', mcs_tag, snr_tag, seed_tag)); % Corrected format specifier
            if ~exist(save_dir_tx, 'dir')
                mkdir(save_dir_tx);
            end

            % save tx data
            tx_sum = params.save.tx_sum_all(:, :, i);
            tx_sig = params.save.tx_sig_all(:, :, i);
            tx_sum_save = [real(tx_sum(:)), imag(tx_sum(:))];
            tx_sig_save = [real(tx_sig(:)), imag(tx_sig(:))];

            % save file names
            tx_sum_name = fullfile(save_dir_tx, sprintf("input.csv"));
            tx_sig_name = fullfile(save_dir_tx, sprintf("output.csv"));

            % save data to csv
            writematrix(tx_sum_save, tx_sum_name);
            writematrix(tx_sig_save, tx_sig_name);
        end

        % 2. save SNR-BER data
        save_root_ber = fullfile(save_root, "BER-SNR");
        if ~exist(save_root_ber, 'dir')
            mkdir(save_root_ber);
        end
        ber_filename = sprintf("ber_curve_MCS_%d_seed_%d.mat", params.info.MCSValue, params.info.randseed);
        ber_file = fullfile(save_root_ber, ber_filename);
        snr_range = params.iter.snr_range;
        ber_curve = params.save.ber_curve;
        save(ber_file, 'snr_range', 'ber_curve', '-v7.3');
    end