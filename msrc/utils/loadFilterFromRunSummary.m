function filter_info = loadFilterFromRunSummary(json_path, expected_len)
    if nargin < 2
        error('loadFilterFromRunSummary requires json_path and expected_len.');
    end

    json_path = string(json_path);
    if strlength(strtrim(json_path)) == 0
        error('External filter JSON path is empty.');
    end

    resolved_path = resolveJsonPath(char(json_path));
    if exist(resolved_path, 'file') ~= 2
        error('External filter JSON not found: %s', resolved_path);
    end

    payload = jsondecode(fileread(resolved_path));
    if ~isfield(payload, 'solved_var') || ~isfield(payload.solved_var, 'hq')
        error('run_summary.json does not contain solved_var.hq: %s', resolved_path);
    end

    coeffs = double(payload.solved_var.hq(:));
    if numel(coeffs) ~= expected_len
        error('Filter length mismatch for %s. Expected %d taps, got %d.', ...
            resolved_path, expected_len, numel(coeffs));
    end
    if ~isreal(coeffs) || any(~isfinite(coeffs))
        error('Invalid FIR coefficients in %s.', resolved_path);
    end

    symmetry_err = max(abs(coeffs - flipud(coeffs)));
    if symmetry_err > 1e-9
        error('FIR coefficients in %s are not symmetric. Max error = %.3e.', ...
            resolved_path, symmetry_err);
    end

    method_name = "UNKNOWN";
    q_bit = NaN;
    if isfield(payload, 'cfg')
        if isfield(payload.cfg, 'method')
            method_name = string(payload.cfg.method);
        end
        if isfield(payload.cfg, 'Q_bit')
            q_bit = double(payload.cfg.Q_bit);
        end
    end

    filter_info = struct( ...
        "coeffs", coeffs, ...
        "source_path", string(resolved_path), ...
        "method", method_name, ...
        "Q_bit", q_bit);
end


function resolved_path = resolveJsonPath(input_path)
    if isAbsolutePath(input_path)
        resolved_path = input_path;
        return;
    end

    helper_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(fileparts(helper_dir));
    resolved_path = fullfile(repo_root, input_path);
end


function tf = isAbsolutePath(path_str)
    tf = false;
    if isempty(path_str)
        return;
    end

    if startsWith(path_str, '\\') || startsWith(path_str, '/')
        tf = true;
        return;
    end

    if numel(path_str) >= 2 && path_str(2) == ':'
        tf = true;
    end
end
