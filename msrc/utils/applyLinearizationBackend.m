function [tx_lin, backend_meta, params] = applyLinearizationBackend(tx_sum, params)
    if ~isfield(params, 'experiment') || ~isfield(params.experiment, 'active_case') ...
            || isempty(fieldnames(params.experiment.active_case))
        tx_lin = tx_sum;
        backend_meta = struct('backend_name', 'passthrough', 'status', 'ok');
        return;
    end

    case_cfg = params.experiment.active_case;
    exchange_dir = fullfile( ...
        params.linearization.exchange_root, ...
        char(case_cfg.case_id), ...
        sprintf('iter_%03d', params.info.IterNum));

    if ~exist(exchange_dir, 'dir')
        mkdir(exchange_dir);
    end

    input_csv = fullfile(exchange_dir, 'input_signal.csv');
    input_meta = fullfile(exchange_dir, 'input_meta.json');
    output_csv = fullfile(exchange_dir, 'output_signal.csv');
    output_meta = fullfile(exchange_dir, 'output_meta.json');

    writeComplexCsv(input_csv, tx_sum);
    writeJsonFile(input_meta, buildBackendPayload(tx_sum, params, case_cfg));

    cmd = buildBackendCommand(params, input_csv, input_meta, output_csv, output_meta);

    [status, cmdout] = system(cmd);
    if status ~= 0
        error('Linearization backend failed for case %s (iter %d).\nCommand: %s\nOutput:\n%s', ...
            params.info.CaseId, params.info.IterNum, cmd, cmdout);
    end

    tx_lin = readComplexCsv(output_csv);
    if numel(tx_lin) ~= numel(tx_sum)
        error('Linearization backend output length mismatch for case %s: got %d expect %d.', ...
            params.info.CaseId, numel(tx_lin), numel(tx_sum));
    end
    tx_lin = reshape(tx_lin, size(tx_sum));

    backend_meta = readJsonFile(output_meta);
    params.linearization.last_exchange_dir = exchange_dir;
    params.linearization.last_backend_stdout = string(cmdout);
end


function cmd = buildBackendCommand(params, input_csv, input_meta, output_csv, output_meta)
    backend_entry = char(params.linearization.backend_entry);
    python_cmd = char(params.linearization.python_cmd);

    if ispc && isWslUncPath(backend_entry)
        distro_name = extractWslDistroName(backend_entry);
        python_cmd_wsl = resolveWslPythonCommand(char(params.repo.root), python_cmd);
        wrapper_ps1 = fullfile(char(params.repo.root), 'tools', 'run_wsl_backend.ps1');
        cmd = sprintf('%s -NoProfile -ExecutionPolicy Bypass -File %s -Distro %s -Python %s -RepoRoot %s -BackendEntry %s -InputCsv %s -InputMeta %s -OutputCsv %s -OutputMeta %s', ...
            quoteShellArg('powershell.exe'), ...
            quoteShellArg(wrapper_ps1), ...
            quoteShellArg(distro_name), ...
            quoteShellArg(python_cmd_wsl), ...
            quoteShellArg(char(params.repo.root)), ...
            quoteShellArg(backend_entry), ...
            quoteShellArg(input_csv), ...
            quoteShellArg(input_meta), ...
            quoteShellArg(output_csv), ...
            quoteShellArg(output_meta));
        return;
    end

    cmd = sprintf('%s %s --input-csv %s --input-meta %s --output-csv %s --output-meta %s', ...
        quoteShellArg(python_cmd), ...
        quoteShellArg(backend_entry), ...
        quoteShellArg(input_csv), ...
        quoteShellArg(input_meta), ...
        quoteShellArg(output_csv), ...
        quoteShellArg(output_meta));
end


function payload = buildBackendPayload(tx_sum, params, case_cfg)
    volterra_pairs = [real(params.linearization.volterra_coeffs(:)), imag(params.linearization.volterra_coeffs(:))];
    model_manifest = char(params.linearization.model_manifest);
    model_bin_dir = char(params.linearization.model_bin_dir);
    if ispc && isWslUncPath(model_manifest)
        model_manifest = convertWindowsPathToWsl(model_manifest);
    end
    if ispc && isWslUncPath(model_bin_dir)
        model_bin_dir = convertWindowsPathToWsl(model_bin_dir);
    end

    payload = struct( ...
        'case_id', char(case_cfg.case_id), ...
        'iter_idx', params.info.IterNum, ...
        'backend_mode', char(case_cfg.backend_mode), ...
        'filter_method', char(case_cfg.filter_method), ...
        'cfr_mode', char(case_cfg.cfr_mode), ...
        'dpd_mode', char(case_cfg.dpd_mode), ...
        'randseed', params.info.randseed, ...
        'signal_length', numel(tx_sum), ...
        'Fs_total', params.rf.Fs_total, ...
        'TargetPeakAmp', params.PA.TargetPeakAmp, ...
        'linearization', struct( ...
            'hc_clip_max', params.linearization.hc_clip_max, ...
            'dpd_iterations', params.linearization.dpd_iterations, ...
            'dpd_step', params.linearization.dpd_step, ...
            'volterra_coeffs_real_imag', volterra_pairs, ...
            'model_manifest', model_manifest, ...
            'model_bin_dir', model_bin_dir));
end


function quoted = quoteShellArg(value)
    value = string(value);
    if ispc
        quoted = sprintf('"%s"', replace(value, '"', '""'));
    else
        value = replace(value, "'", "'\"'\"'");
        quoted = sprintf('''%s''', value);
    end
end


function tf = isWslUncPath(path_str)
    tf = startsWith(string(path_str), "\\wsl.localhost\") || startsWith(string(path_str), "\\wsl$\");
end


function distro_name = extractWslDistroName(path_str)
    path_str = char(path_str);
    tokens = regexp(path_str, '^\\\\wsl(?:\.localhost)?\\([^\\]+)\\', 'tokens', 'once');
    if isempty(tokens)
        error('Unable to extract WSL distro name from path: %s', path_str);
    end
    distro_name = tokens{1};
end


function wsl_path = convertWindowsPathToWsl(path_str)
    path_str = char(path_str);
    unc_tokens = regexp(path_str, '^\\\\wsl(?:\.localhost)?\\[^\\]+\\(.*)$', 'tokens', 'once');
    if ~isempty(unc_tokens)
        suffix = strrep(unc_tokens{1}, '\', '/');
        wsl_path = ['/' suffix];
        return;
    end

    drive_tokens = regexp(path_str, '^([A-Za-z]):\\(.*)$', 'tokens', 'once');
    if ~isempty(drive_tokens)
        drive_letter = lower(drive_tokens{1});
        suffix = strrep(drive_tokens{2}, '\', '/');
        wsl_path = sprintf('/mnt/%s/%s', drive_letter, suffix);
        return;
    end

    wsl_path = strrep(path_str, '\', '/');
end


function python_cmd_wsl = normalizeWslPythonCommand(python_cmd)
    token = lower(strtrim(string(python_cmd)));
    switch token
        case {"python", "python.exe", "py"}
            python_cmd_wsl = "python3";
        otherwise
            python_cmd_wsl = string(python_cmd);
    end
end


function python_cmd_wsl = resolveWslPythonCommand(repo_root, python_cmd)
    venv_python_windows = fullfile(repo_root, '.venv', 'bin', 'python3');
    if exist(venv_python_windows, 'file') == 2
        python_cmd_wsl = convertWindowsPathToWsl(venv_python_windows);
        return;
    end

    python_cmd_wsl = normalizeWslPythonCommand(python_cmd);
end
