function writeJsonFile(file_path, payload)
    try
        json_text = jsonencode(payload, 'PrettyPrint', true);
    catch
        json_text = jsonencode(payload);
    end
    file_id = fopen(file_path, 'w');
    if file_id == -1
        error('Failed to open JSON file for writing: %s', file_path);
    end
    cleaner = onCleanup(@() fclose(file_id));
    fprintf(file_id, '%s', json_text);
end
