function payload = readJsonFile(file_path)
    if exist(file_path, 'file') ~= 2
        error('JSON file not found: %s', file_path);
    end
    payload = jsondecode(fileread(file_path));
end
