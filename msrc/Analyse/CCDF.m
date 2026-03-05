function [dB_range, CCDF_vals] = CCDF(inSig, start_dB, end_dB, margin)
% Compute CCDF of the given signal array
% Inputs:
%   inSig    - The input signal array (can be vector or matrix)
%   start_dB - (Optional) CCDF calculation start in dB (default: -40 dB)
%   end_dB   - (Optional) CCDF calculation end in dB (default: 10 dB)
%   margin   - (Optional) Step size for dB range (default: 1 dB)
%
% Outputs:
%   dB_range - The dB range for which CCDF is calculated
%   CCDF_vals - The CCDF values corresponding to each dB in dB_range

    if nargin < 2, start_dB = -40; end_dB = 10; margin = 1; end
    if nargin < 3, end_dB = 10; margin = 1; end
    if nargin < 4, margin = 1; end

    dB_range = start_dB:margin:end_dB;

    % Normalize power
    power_vals = abs(inSig).^2;
    power_vals = power_vals / mean(power_vals(:));  % Normalize to average power = 1
    power_dB = 10 * log10(power_vals(:));           % Convert to dB

    % CCDF calculation
    CCDF_vals = zeros(size(dB_range));
    for i = 1:length(dB_range)
        CCDF_vals(i) = sum(power_dB > dB_range(i)) / length(power_dB);
    end
end
