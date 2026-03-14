function artifact_paths = generatePaperFiguresAndTable(result_files, key_snr_points, report_root)
    if nargin < 1 || isempty(result_files)
        error('result_files must not be empty.');
    end
    if nargin < 2 || isempty(key_snr_points)
        key_snr_points = [-5 15];
    end
    if nargin < 3 || strlength(strtrim(string(report_root))) == 0
        repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        report_root = fullfile(repo_root, 'report', 'exp');
    end

    report_root = char(string(report_root));
    if ~exist(report_root, 'dir')
        mkdir(report_root);
    end

    result_files = string(result_files(:));
    datasets = repmat(struct( ...
        'file', '', ...
        'snr_range', [], ...
        'case_ids', {{}}, ...
        'ber_curve_by_method', [], ...
        'evm_curve_by_method', [], ...
        'case_configs', struct([]), ...
        'mcs_value', 0, ...
        'modulation_name', '', ...
        'key_snr_points', []), numel(result_files), 1);

    for idx = 1:numel(result_files)
        data = load(char(result_files(idx)));
        if ~isfield(data, 'evm_curve_by_method')
            error('Missing evm_curve_by_method in %s. Re-run the BER/EVM sweep with the updated flow.', char(result_files(idx)));
        end

        datasets(idx).file = char(result_files(idx));
        datasets(idx).snr_range = double(data.snr_range(:)');
        datasets(idx).case_ids = normalizeCaseIds(data.case_ids);
        datasets(idx).ber_curve_by_method = double(data.ber_curve_by_method);
        datasets(idx).evm_curve_by_method = double(data.evm_curve_by_method);
        if isfield(data, 'case_configs')
            datasets(idx).case_configs = data.case_configs;
        end
        if isfield(data, 'mcs_value')
            datasets(idx).mcs_value = double(data.mcs_value);
        else
            datasets(idx).mcs_value = parseMcsValueFromFilename(char(result_files(idx)));
        end
        if isfield(data, 'modulation_name')
            datasets(idx).modulation_name = char(string(data.modulation_name));
        else
            datasets(idx).modulation_name = char(getModulationNameFromMCS(datasets(idx).mcs_value));
        end
        if isfield(data, 'key_snr_points')
            datasets(idx).key_snr_points = double(data.key_snr_points(:)');
        else
            datasets(idx).key_snr_points = key_snr_points;
        end
    end

    [~, order] = sort([datasets.mcs_value]);
    datasets = datasets(order);
    ordered_result_files = cellstr(result_files(order));

    artifact_paths = struct();
    artifact_paths.fig1_png = fullfile(report_root, 'fig1_snr_ber_all_mcs.png');
    artifact_paths.fig1_pdf = fullfile(report_root, 'fig1_snr_ber_all_mcs.pdf');
    artifact_paths.fig2_png = fullfile(report_root, 'fig2_snr_evm_all_mcs.png');
    artifact_paths.fig2_pdf = fullfile(report_root, 'fig2_snr_evm_all_mcs.pdf');
    artifact_paths.table2_csv = fullfile(report_root, 'table2_key_snr_summary.csv');
    artifact_paths.table2_md = fullfile(report_root, 'table2_key_snr_summary.md');
    artifact_paths.manifest_json = fullfile(report_root, 'paper_artifact_manifest.json');

    plotMetricFigure(datasets, 'ber', artifact_paths.fig1_png, artifact_paths.fig1_pdf);
    plotMetricFigure(datasets, 'evm', artifact_paths.fig2_png, artifact_paths.fig2_pdf);

    summary_table = buildTable2Summary(datasets, key_snr_points);
    writetable(summary_table, artifact_paths.table2_csv);
    writeTable2Markdown(summary_table, artifact_paths.table2_md, key_snr_points);

    manifest = struct();
    manifest.result_files = ordered_result_files;
    manifest.key_snr_points = key_snr_points;
    manifest.mcs_values = [datasets.mcs_value];
    manifest.artifacts = artifact_paths;
    writeJsonFile(artifact_paths.manifest_json, manifest);
end


function plotMetricFigure(datasets, metric_name, png_path, pdf_path)
    preferred_case_order = { ...
        'migo_no_cfr_no_dpd', ...
        'migo_hc_no_dpd', ...
        'migo_no_cfr_dpd', ...
        'migo_no_cfr_volterra', ...
        'migo_hc_volterra', ...
        'migo_joint_cfr_dpd' ...
    };
    case_order = resolveAvailableCaseOrder(datasets, preferred_case_order);
    legend_labels = cellfun(@(case_id) char(getPaperCaseDisplayName(case_id)), case_order, 'UniformOutput', false);

    colors = lines(numel(case_order));
    line_styles = {'-', '--', '-.', ':', '-', '--', '-.'};
    markers = {'o', 's', '^', 'd', 'x', 'v', 'p'};

    y_limits = determineYLimits(datasets, case_order, metric_name);
    fig = figure('Color', 'w', 'Position', [100 100 1680 560]);
    tl = tiledlayout(1, numel(datasets), 'TileSpacing', 'compact', 'Padding', 'compact');

    legend_handles = gobjects(numel(case_order), 1);
    for dataset_idx = 1:numel(datasets)
        ax = nexttile(tl, dataset_idx);
        hold(ax, 'on');

        for case_idx = 1:numel(case_order)
            row_idx = findCaseRowOrEmpty(datasets(dataset_idx).case_ids, case_order{case_idx});
            if isempty(row_idx)
                continue;
            end
            x_vals = datasets(dataset_idx).snr_range;
            if strcmp(metric_name, 'ber')
                y_vals = datasets(dataset_idx).ber_curve_by_method(row_idx, :);
                handle = semilogy(ax, x_vals, y_vals, ...
                    'Color', colors(case_idx, :), ...
                    'LineStyle', line_styles{case_idx}, ...
                    'Marker', markers{case_idx}, ...
                    'LineWidth', 1.7, ...
                    'MarkerSize', 6, ...
                    'MarkerFaceColor', 'w');
            else
                y_vals = 100 * datasets(dataset_idx).evm_curve_by_method(row_idx, :);
                handle = plot(ax, x_vals, y_vals, ...
                    'Color', colors(case_idx, :), ...
                    'LineStyle', line_styles{case_idx}, ...
                    'Marker', markers{case_idx}, ...
                    'LineWidth', 1.7, ...
                    'MarkerSize', 6, ...
                    'MarkerFaceColor', 'w');
            end

            if dataset_idx == 1
                legend_handles(case_idx) = handle;
            end
        end

        grid(ax, 'on');
        box(ax, 'on');
        xlim(ax, [datasets(dataset_idx).snr_range(1), datasets(dataset_idx).snr_range(end)]);
        ylim(ax, y_limits);
        xlabel(ax, 'SNR (dB)');
        if dataset_idx == 1
            if strcmp(metric_name, 'ber')
                ylabel(ax, 'BER');
            else
                ylabel(ax, 'EVM (%)');
            end
        end
        title(ax, sprintf('MCS %d (%s)', ...
            datasets(dataset_idx).mcs_value, datasets(dataset_idx).modulation_name));
    end

    if strcmp(metric_name, 'ber')
        title(tl, '图 1：固定 MIGO 前端下的 SNR-BER');
    else
        title(tl, '图 2：固定 MIGO 前端下的 SNR-EVM');
    end

    lgd = legend(legend_handles, legend_labels, 'Orientation', 'horizontal', 'Interpreter', 'none');
    lgd.Layout.Tile = 'south';

    saveFigureDualFormat(fig, png_path, pdf_path);
    close(fig);
end


function y_limits = determineYLimits(datasets, case_order, metric_name)
    all_vals = [];
    for dataset_idx = 1:numel(datasets)
        for case_idx = 1:numel(case_order)
            row_idx = findCaseRowOrEmpty(datasets(dataset_idx).case_ids, case_order{case_idx});
            if isempty(row_idx)
                continue;
            end
            if strcmp(metric_name, 'ber')
                curve_vals = datasets(dataset_idx).ber_curve_by_method(row_idx, :);
                curve_vals = curve_vals(curve_vals > 0);
            else
                curve_vals = 100 * datasets(dataset_idx).evm_curve_by_method(row_idx, :);
                curve_vals = curve_vals(curve_vals >= 0);
            end
            all_vals = [all_vals, curve_vals]; %#ok<AGROW>
        end
    end

    if isempty(all_vals)
        error('No valid %s values were found for plotting.', metric_name);
    end

    if strcmp(metric_name, 'ber')
        lower_bound = 10 ^ floor(log10(max(min(all_vals), 1e-8)));
        upper_bound = 10 ^ ceil(log10(max(all_vals)));
        y_limits = [lower_bound, upper_bound];
    else
        upper_bound = max(all_vals);
        if upper_bound <= 0
            upper_bound = 1;
        end
        y_limits = [0, upper_bound * 1.1];
    end
end


function summary_table = buildTable2Summary(datasets, key_snr_points)
    joint_case_ids = {'migo_joint_cfr_dpd', 'wls_joint_cfr_dpd', 'swls_joint_cfr_dpd'};
    rows = struct( ...
        'mcs_value', {}, ...
        'modulation', {}, ...
        'filter', {}, ...
        'linearization', {}, ...
        'snr_m5_ber', {}, ...
        'snr_m5_evm_percent', {}, ...
        'snr_15_ber', {}, ...
        'snr_15_evm_percent', {});

    for dataset_idx = 1:numel(datasets)
        neg5_idx = findSNRIndex(datasets(dataset_idx).snr_range, key_snr_points(1));
        pos15_idx = findSNRIndex(datasets(dataset_idx).snr_range, key_snr_points(2));

        for case_idx = 1:numel(joint_case_ids)
            row_idx = findCaseRowOrEmpty(datasets(dataset_idx).case_ids, joint_case_ids{case_idx});
            if isempty(row_idx)
                continue;
            end

            rows(end + 1) = struct( ... %#ok<AGROW>
                'mcs_value', datasets(dataset_idx).mcs_value, ...
                'modulation', string(datasets(dataset_idx).modulation_name), ...
                'filter', string(getFilterLabelForJointCase(joint_case_ids{case_idx})), ...
                'linearization', "Joint CFR-DPD", ...
                'snr_m5_ber', datasets(dataset_idx).ber_curve_by_method(row_idx, neg5_idx), ...
                'snr_m5_evm_percent', 100 * datasets(dataset_idx).evm_curve_by_method(row_idx, neg5_idx), ...
                'snr_15_ber', datasets(dataset_idx).ber_curve_by_method(row_idx, pos15_idx), ...
                'snr_15_evm_percent', 100 * datasets(dataset_idx).evm_curve_by_method(row_idx, pos15_idx));
        end
    end

    if isempty(rows)
        summary_table = table( ...
            zeros(0, 1), strings(0, 1), strings(0, 1), strings(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
            'VariableNames', { ...
                'mcs_value', ...
                'modulation', ...
                'filter', ...
                'linearization', ...
                'snr_m5_ber', ...
                'snr_m5_evm_percent', ...
                'snr_15_ber', ...
                'snr_15_evm_percent' ...
            });
        return;
    end

    summary_table = struct2table(rows, 'AsArray', true);
end


function writeTable2Markdown(summary_table, md_path, key_snr_points)
    file_id = fopen(md_path, 'w');
    if file_id == -1
        error('Failed to open markdown file for writing: %s', md_path);
    end
    cleaner = onCleanup(@() fclose(file_id));

    fprintf(file_id, '# 表 2：关键 SNR 点下的 BER / EVM 汇总\n\n');
    fprintf(file_id, '固定线性化方式为 `Joint CFR-DPD`，关键 SNR 点固定为 `%d dB` 和 `%d dB`。\n\n', ...
        key_snr_points(1), key_snr_points(2));
    fprintf(file_id, '| MCS | 调制 | 滤波器 | 线性化 | SNR=%d BER | SNR=%d EVM (%%) | SNR=%d BER | SNR=%d EVM (%%) |\n', ...
        key_snr_points(1), key_snr_points(1), key_snr_points(2), key_snr_points(2));
    fprintf(file_id, '|---:|---|---|---|---:|---:|---:|---:|\n');

    for row_idx = 1:height(summary_table)
        fprintf(file_id, '| %d | %s | %s | %s | %.6e | %.3f | %.6e | %.3f |\n', ...
            summary_table.mcs_value(row_idx), ...
            char(summary_table.modulation(row_idx)), ...
            char(summary_table.filter(row_idx)), ...
            char(summary_table.linearization(row_idx)), ...
            summary_table.snr_m5_ber(row_idx), ...
            summary_table.snr_m5_evm_percent(row_idx), ...
            summary_table.snr_15_ber(row_idx), ...
            summary_table.snr_15_evm_percent(row_idx));
    end
end


function case_ids = normalizeCaseIds(raw_case_ids)
    if isstring(raw_case_ids)
        case_ids = cellstr(raw_case_ids(:));
        return;
    end
    if iscell(raw_case_ids)
        case_ids = cellfun(@(value) char(string(value)), raw_case_ids(:), 'UniformOutput', false);
        return;
    end
    case_ids = cellstr(string(raw_case_ids(:)));
end


function row_idx = findCaseRow(case_ids, target_case_id)
    row_idx = find(strcmp(case_ids, target_case_id), 1);
    if isempty(row_idx)
        error('Case %s was not found in the loaded compare result.', target_case_id);
    end
end


function row_idx = findCaseRowOrEmpty(case_ids, target_case_id)
    row_idx = find(strcmp(case_ids, target_case_id), 1);
end


function snr_idx = findSNRIndex(snr_range, target_snr)
    snr_idx = find(abs(snr_range - target_snr) < 1e-9, 1);
    if isempty(snr_idx)
        error('Target SNR %.2f dB is not present in the saved snr_range.', target_snr);
    end
end


function mcs_value = parseMcsValueFromFilename(result_file)
    tokens = regexp(char(result_file), 'MCS_(\d+)_seed_', 'tokens', 'once');
    if isempty(tokens)
        error('Unable to parse MCS value from %s.', result_file);
    end
    mcs_value = str2double(tokens{1});
end


function case_order = resolveAvailableCaseOrder(datasets, preferred_case_order)
    available_case_ids = {};
    for dataset_idx = 1:numel(datasets)
        available_case_ids = [available_case_ids, datasets(dataset_idx).case_ids(:)']; %#ok<AGROW>
    end
    available_case_ids = unique(available_case_ids, 'stable');

    case_order = {};
    for idx = 1:numel(preferred_case_order)
        if any(strcmp(available_case_ids, preferred_case_order{idx}))
            case_order{end + 1} = preferred_case_order{idx}; %#ok<AGROW>
        end
    end

    for idx = 1:numel(available_case_ids)
        if ~any(strcmp(case_order, available_case_ids{idx}))
            case_order{end + 1} = available_case_ids{idx}; %#ok<AGROW>
        end
    end

    if isempty(case_order)
        error('No case data was found for plotting.');
    end
end


function filter_label = getFilterLabelForJointCase(case_id)
    switch string(case_id)
        case "migo_joint_cfr_dpd"
            filter_label = "MIGO";
        case "wls_joint_cfr_dpd"
            filter_label = "WLS";
        case "swls_joint_cfr_dpd"
            filter_label = "SWLS";
        otherwise
            filter_label = string(case_id);
    end
end


function saveFigureDualFormat(fig, png_path, pdf_path)
    saveFigureOne(fig, png_path, 'png');
    saveFigureOne(fig, pdf_path, 'pdf');
end


function saveFigureOne(fig, target_path, file_kind)
    target_path = char(target_path);
    save_path = target_path;
    temp_path = '';
    if ispc && isWslUncPathLocal(target_path)
        temp_path = [tempname, '.', file_kind];
        save_path = temp_path;
    end

    try
        switch lower(file_kind)
            case 'png'
                exportgraphics(fig, save_path, 'Resolution', 300);
            case 'pdf'
                exportgraphics(fig, save_path, 'ContentType', 'vector');
            otherwise
                saveas(fig, save_path);
        end
    catch
        saveas(fig, save_path);
    end

    if ~isempty(temp_path)
        target_dir = fileparts(target_path);
        if ~exist(target_dir, 'dir')
            mkdir(target_dir);
        end
        copyfile(temp_path, target_path);
        delete(temp_path);
    end
end


function tf = isWslUncPathLocal(path_str)
    tf = startsWith(string(path_str), "\\wsl.localhost\") || startsWith(string(path_str), "\\wsl$\");
end
