function [outSig] = applyCFR(inSig, params)
    % applyCFR: chose and apply diverse Crest Factor Reduction Algorithm, plot the result
    % Input:
    %   inSig: input signal
    %   params: parameters
    % Output:
    %   outSig: output signal

    % The CCDF Before CFR
    if isfield(params.plot, 'CFR') && params.plot.CFR
        figure;
        pm = powermeter(ComputeCCDF=true);
        allInSig = mean(inSig,[2,3]);
        avgP = pm(allInSig);
        pm(inSig(:,1,1));
        disp(avgP)
        plotCCDF(pm,GaussianReference=true)
    end

    % CFR_Params.Method 0: HC 1: CAF 2: ...
    MethodParams = params.CFR;
    MethodParams.timeEnd = length(inSig(:)) * params.time.Ts;
    MethodParams.showFig = params.plot.CFR;
    MethodParams.save = params.plot.save;
    MethodParams.save_path = params.plot.save_path;
    MethodParams.save_fmt = params.plot.save_fmt;
    Method = "";
    switch params.CFR.Method
        case 0
            % No CFR
            outSig = inSig;
        case 1
            % Hard clipper
            Method = sprintf("HC %3f",MethodParams.ClipMax);
            outSig = HC(inSig, MethodParams);
        case 2
        
    end

    if isfield(params.plot, 'CFR') && params.plot.CFR
        T_title = sprintf("CRC Method[%s]_Compared between before and after application", Method);
        figure('Name',T_title);
        hold on;
        % Compare the CCDF Before and After CFR
        [relpower1,prob1] = CCDF(outSig);
        [relpower2,prob2] = CCDF(inSig);
        semilogy(relpower1,prob1)
        semilogy(relpower2,prob2)
        hold off;
        xlabel('Relative Power (dB)');
        ylabel('Probability (%)');
        grid on;
        title('CCDF Measurement');
        legend('W. CFR', 'WO. CFR', 'Location', 'Best');
        if params.plot.save == 1
            saveas(gcf, sprintf("%s/%s",params.PicPath, T_title), params.PicFmt);
        end
    end
end

