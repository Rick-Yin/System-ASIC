function display_name = getPaperCaseDisplayName(case_id)
    switch string(case_id)
        case "migo_no_cfr_no_dpd"
            display_name = "NoCFR+NoDPD";
        case "migo_hc_no_dpd"
            display_name = "HC-only";
        case "migo_no_cfr_dpd"
            display_name = "DPD-only";
        case "migo_no_cfr_volterra"
            display_name = "Volterra-only";
        case "migo_hc_volterra"
            display_name = "HC+Volterra";
        case "migo_joint_cfr_dpd"
            display_name = "Joint CFR-DPD";
        case "wls_joint_cfr_dpd"
            display_name = "WLS + Joint CFR-DPD";
        case "swls_joint_cfr_dpd"
            display_name = "SWLS + Joint CFR-DPD";
        otherwise
            display_name = string(case_id);
    end
end
