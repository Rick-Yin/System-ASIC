function signal = readComplexCsv(file_path)
    file_id = fopen(file_path, 'r');
    if file_id == -1
        error('Failed to open CSV file for reading: %s', file_path);
    end
    cleaner = onCleanup(@() fclose(file_id));

    data = textscan(file_id, '%f%f', 'Delimiter', ',', 'CollectOutput', true);
    data = data{1};
    if isempty(data)
        signal = complex([], []);
        return;
    end
    if size(data, 2) == 1
        signal = complex(data(:, 1), zeros(size(data, 1), 1));
        return;
    end
    signal = complex(data(:, 1), data(:, 2));
end
