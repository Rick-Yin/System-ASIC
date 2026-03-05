function [] = plotSCFA(SCSig, params)
    % plotSCFA Plot the subcarrier frequency-amplitude graph
    %
    % plotSCFA(SCSig, params) Plot the subcarrier frequency-amplitude graph
    %
    % SCSig: The subcarrier signal
    % params: The parameters of the plot
    %
    % Example:
    %
    % plotSCFA(SCSig, struct("title", "子载波频率-幅度图", "chozSC",1:4));


    % figure('Name', params.title);
    index = params.chozSC;
    interval = params.interval;
    showSig = SCSig(index);
    N_SC = length(index);
    Ts = 1 / params.fs;

    n = params.sample;
    T = linspace(0, Ts * n, n);

    sc = zeros(1, length(T));
    Spectrum = zeros(N_SC, length(T));
    for i = 1:N_SC
        sc(i, :) = real(showSig(i)) * cos(2 * pi * (i-1) * interval * T) - imag(showSig(i)) * sin(2 * pi * (i-1) * interval * T);
        Spectrum(i, :) = fft(sc(i, :) ./ n);
    end


    % show the subcarrier signal in one figure
    figure('Name', '子载波时域信号');
    hold on;
    for i = 1:N_SC
        plot(T * 1e-6, sc(i, :));
    end
    set(get(gca, 'XLabel'), 'String', ' Time (us)');
    set(get(gca, 'YLabel'), 'String', ' Amplitude');
    hold off;

    % show the spectrum of the subcarrier signal in one figure

    figure('Name', '子载波频谱');
    hold on;

    for i = 1:N_SC
        A = fftshift(Spectrum(i, :));
        f = linspace(-params.fs / 2, params.fs / 2 - 1, n);
        plot(f * 1e-6, abs(A));
    end
    set(get(gca, 'XLabel'), 'String', ' Frequency (MHz)');
    set(get(gca, 'YLabel'), 'String', ' Amplitude');
    hold off;


end

