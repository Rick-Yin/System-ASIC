function rx = Channel(tx, SNR_dB, params)
    if ~isfield(params, 'channel') || ~isfield(params.channel, 'type')
        params.channel.type = 'awgn';
    end
    switch lower(params.channel.type)
        case 'awgn'
            rx = awgn(tx, SNR_dB, 'measured');
        case 'rayleigh'
            h = (randn(size(tx)) + 1j * randn(size(tx))) / sqrt(2);
            rx_faded = tx .* h;
            rx = awgn(rx_faded, SNR_dB, 'measured');
        case 'ideal'
            rx = tx; % Assuming ideal channel means no change to the transmitted signal
        otherwise
            error('Unsupported channel type: %s', params.channel.type);
    end
end