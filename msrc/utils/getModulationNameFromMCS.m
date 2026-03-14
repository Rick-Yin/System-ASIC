function modulation_name = getModulationNameFromMCS(mcs_value)
    [mod_order, ~] = getMCSValue(mcs_value);

    switch mod_order
        case 2
            modulation_name = "QPSK";
        case 4
            modulation_name = "16QAM";
        case 6
            modulation_name = "64QAM";
        case 8
            modulation_name = "256QAM";
        case 10
            modulation_name = "1024QAM";
        case 12
            modulation_name = "4096QAM";
        otherwise
            modulation_name = sprintf('%dQAM', 2 ^ mod_order);
    end
end
