function writeComplexCsv(file_path, signal)
    signal = signal(:);
    data = [real(signal), imag(signal)];
    file_id = fopen(file_path, 'w');
    if file_id == -1
        error('Failed to open CSV file for writing: %s', file_path);
    end
    cleaner = onCleanup(@() fclose(file_id));
    fprintf(file_id, '%.18e,%.18e\n', data.');
end
