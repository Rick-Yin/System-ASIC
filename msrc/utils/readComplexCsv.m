function signal = readComplexCsv(file_path)
    data = readmatrix(file_path);
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
