function [num_diff, ranges, diff_positions] = compareArrays(arr1, arr2, threshold)
    % 输入：
    % arr1, arr2: 要比较的两个数组
    % threshold: 误差阈值，两个元素差的幅度小于该值认为相同
    
    % 确保输入数组的长度相同
    if length(arr1) ~= length(arr2)
        error('两个数组长度必须相同');
    end
    
    % 计算元素差的幅度并找出不相同的元素
    diff = abs(arr1 - arr2) > threshold;
    
    % 计算不相同的元素个数
    num_diff = sum(diff);
    
    % 初始化结果
    ranges = [];
    diff_positions = [];
    
    % 找出不相同的位置
    diff_idx = find(diff);
    
    if ~isempty(diff_idx)
        % 寻找不相同的位置范围
        range_start = diff_idx(1); % 初始范围的开始
        for i = 2:length(diff_idx)
            % 如果当前位置和前一个位置不连续，保存当前范围并重新开始
            if diff_idx(i) ~= diff_idx(i-1) + 1
                ranges = [ranges; range_start, diff_idx(i-1)];
                range_start = diff_idx(i);
            end
        end
        % 添加最后一个范围
        ranges = [ranges; range_start, diff_idx(end)];
        
        % 存储不相同位置及对应元素
        for i = 1:length(diff_idx)
            diff_positions = [diff_positions; diff_idx(i), arr1(diff_idx(i)), arr2(diff_idx(i))];
        end
    end
end
