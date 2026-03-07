function writeComplexCsv(file_path, signal)
    signal = signal(:);
    data = [real(signal), imag(signal)];
    writematrix(data, file_path);
end
