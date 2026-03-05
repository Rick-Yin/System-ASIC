function outSig = PA(inSig, params)
    % PA: Power Amplifier
    %   inSig: input signal
    %   outSig: output signal
    
    %% PA 1: From ZKJS
    % % Parameters
    % b1 = 1.0108+1i*0.0858;
    % b3 = 0.0879-1i*0.1583;
    % b5 = -1.0992-1i*0.8891;
    % G  = 1;
    % 
    % % Initialization
    % SignalIn = [0, 0, reshape(inSig, 1, [])];
    % LenSignal = length(SignalIn);
    % inSigBuffer = zeros([1, LenSignal]);
    % outSig = zeros([1, LenSignal]);
    % 
    % % PA
    % for i = 3:LenSignal
    %     inSigBuffer(i)= SignalIn(i) + 0.5*SignalIn(i - 2) + 0.2*inSigBuffer(i - 1);
    %     outSig(i)= 1/G * ( b1 + b3 * abs(inSigBuffer(i))^2 + b5 *abs(inSigBuffer(i))^4 )*inSigBuffer(i);
    % end
    % outSig = outSig(3:end);
    % outSig = reshape(outSig, size(inSig));

    %% PA2: From "Analysis on LUT Based Predistortion Method for HPA with Memory"  qpsk
    coef = [ 1.0513 + 0.0904j, -0.0680 - 0.0023j,  0.0289 + 0.0054j;
             0.0542 - 0.2900j,  0.2234 + 0.2317j, -0.0621 - 0.0932j;
            -0.9657 - 0.7028j, -0.2451 - 0.3735j,  0.1229 + 0.1508j];

    SignalIn = [0, 0, reshape(inSig, 1, [])];

    inSig_O1 = SignalIn;
    inSig_O3 = SignalIn .* abs(SignalIn).^(3-1);
    inSig_O5 = SignalIn .* abs(SignalIn).^(5-1);
    inSig_M = [inSig_O1; inSig_O3; inSig_O5];
    coef = flip(coef);
    outSig = conv2(inSig_M, coef, "valid");

    outSig = reshape(outSig, size(inSig));
    outSig = outSig * params.PA.Gain;

    %% ----------- 可视化分析（根据 params.plot 控制） -----------
    if isfield(params, 'plot')
        x = reshape(inSig, [], 1);   % 输入信号展平
        y = reshape(outSig, [], 1);  % 输出信号展平

        amp_in = abs(x);
        amp_out = abs(y);
        phase_in = angle(x);
        phase_out = angle(y);
        phase_diff = wrapToPi(phase_out - phase_in); % AM-PM曲线

        % 1. AM-AM 图：幅度映射
        if isfield(params.plot, 'AMAM') && params.plot.AMAM
            figure; scatter(amp_in, amp_out, '.');
            title('AM-AM Characteristic');
            xlabel('Input Amplitude'); ylabel('Output Amplitude');
            grid on;
        end

        % 2. AM-PM 图：相位映射
        if isfield(params.plot, 'AMPM') && params.plot.AMPM
            figure; scatter(amp_in, phase_diff, '.');
            title('AM-PM Characteristic');
            xlabel('Input Amplitude'); ylabel('Phase Difference (rad)');
            grid on;
        end

        % 3. 输出功率 vs 输入功率
        if isfield(params.plot, 'PoutPin') && params.plot.PoutPin
            P_in = 10*log10(abs(x).^2 + eps);   % dB
            P_out = 10*log10(abs(y).^2 + eps);
            figure; scatter(P_in, P_out, '.');
            title('Output Power vs Input Power');
            xlabel('Input Power [dB]'); ylabel('Output Power [dB]');
            grid on;
        end

        % 4. 频谱图 + ACLR
        if isfield(params.plot, 'ACLR') && params.plot.ACLR
            Nfft = 4096;
            [pxx, f] = periodogram(y, [], Nfft, params.rf.Fs_total, 'centered');
            pxx_dB = 10*log10(pxx / max(pxx)); % dB归一化
            figure; plot(f/1e6, pxx_dB);
            title('Output Spectrum (ACLR Analysis)');
            xlabel('Frequency [MHz]'); ylabel('Power [dB]');
            grid on;
        end
    end

end