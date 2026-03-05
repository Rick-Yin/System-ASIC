function plotnonlinearDistortion(inSig, outSig)
    % plotnonlinearDistortion: plot nonlinear distortion
    %   inSig: input signal
    %   outSig: output signal

    inSig = reshape(inSig, 1, []);
    outSig = reshape(outSig, 1, []);
    
    nonlinearDistortion = abs(outSig) - abs(inSig);
    figure("Name", "Nonlinear Distortion");
    plot(nonlinearDistortion);
    title('Nonlinear Distortion');
    xlabel('Sample Index');
    ylabel('Magnitude of Distortion');
end