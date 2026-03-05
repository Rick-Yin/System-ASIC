function [MD_Mode, R] = getMCSValue(mcs_index)
    %   getMCSValue: Based on the MCS index, return the modulation and coding scheme
    %   [MD_Mode, R] = getMCSValue(mcs_index)
    %   mcs_index: MCS index
    %   MD_Mode: Modulation and coding scheme
    %           0: QPSK
    %           1: 16QAM
    %           2: 64QAM
    %           3: 256QAM
    %           4: 1024QAM
    %           5: 4096QAM
    %   R: Code rate, x/1024
    MCSTable = [...
    0, 128; 0, 168; 0, 220; 0, 284; 0, 360; 0, 452; 0, 552; 0, 660; ... % QPSK      MCS 0-7
    1, 360; 1, 436; 1, 516; 1, 600; 1, 688; ...                         % 16QAM     MCS 8-12
    2, 476; 2, 544; 2, 612; 2, 684; 2, 756; 2, 828; 2, 896; ...         % 64QAM     MCS 13-19
    3, 692; 3, 752; 3, 812; 3, 868; 3, 916; 3, 960; ...                 % 256QAM    MCS 20-25
    4, 832; 4, 904; 4, 960; ...                                         % 1024QAM   MCS 26-28
    5, 840; 5, 908; 5, 960; ...                                         % 4096QAM   MCS 29-31
    ];
    Value = MCSTable(mcs_index + 1,:);
    [MD_Mode, R] = deal(2*(Value(1)+1), Value(2)/1024);
end

