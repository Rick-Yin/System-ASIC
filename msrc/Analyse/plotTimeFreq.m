function plotTimeFreq(Signal, params)
    % plotTimeFreq: Plot the time-domain and frequency-domain graphs of the signal
    %
    % Inputs:
    %   Signal  - The input time-domain signal (complex).
    %   fs      - The sampling frequency in Hz.
    %
    % Example:
    %   plotTimeFreq(Signal, struct()); % Signal

    % Length of the signal
    SignalTime = reshape(Signal, 1, []);
    N = length(SignalTime);
    
    % Time axis for plotting
    t = linspace(0, (N-1) / params.fs, N) * 1e6;  % Time vector from 0 to the duration
    
    % Plot time-domain signal
    figure('Name',params.T_Title);

    plot(t, real(SignalTime), 'b', 'DisplayName', 'Real part');
    hold on;
    plot(t, imag(SignalTime), 'r', 'DisplayName', 'Imaginary part');
    xlabel('时间 (μs)');
    ylabel('幅度');
    legend;
    grid on;

    if params.save == 1
        saveas(gcf, sprintf("%s/%s",params.PicPath, params.T_Title), params.PicFmt);
    end

    % Frequency-domain computation (FFT)
    figure('Name',params.F_Title);
    N = length(Signal);
    f = linspace(0, params.fs, N)/1e6;  % Frequency axis (centered around 0 MHz)

    Spectrum =  20*log10(mean(abs(fft(Signal)) , 2 ));

    % Plot frequency-domain spectrum
    plot(f, Spectrum);
    xlabel('频率 (MHz)');
    ylabel('幅度');
    
    grid on;    
    if params.save == 1
        saveas(gcf, sprintf("%s/%s",params.PicPath, params.F_Title), params.PicFmt);   
    end
   
end
