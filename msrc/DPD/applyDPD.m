function outSig = applyDPD(inSig, params)
    % applyDPD - Apply DPD to the input signal
    %   inSig: input signal
    %   params: parameters
    %   outSig: output signal
    
    %% Gen Model Params
    
    switch params.DPD.Method
        case 0
            outSig = inSig;
    end

end