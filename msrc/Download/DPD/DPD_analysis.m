% DPD_analysis.m
% Copyright 2014 The MathWorks, Inc.
disp(['Executing ',mfilename,'.m...']);

tic;
%% Test data used to derive coefs
load meas_pa;
pa_in   = pa_in;
pa_out  = pa_out;

toss  = 500;             % ignore initial data that could have transients 
pad   = 600;             % room to play at the end of the data set. 
traininglen = 20e4; % Arbitrary subset of pa_in data used to derive coefs
if traininglen > (length(pa_in)-pad-toss)
    error('Pick smaller subset for traininglen');
end

%% PA and DPD model parameters
memorylen_pa    = 3; %M
degree_pa       = 3; %K
degree_pd       = 5; 
memorylen_pd    = 5; 

coef_pd=complex(zeros(degree_pd*memorylen_pd,1));
coef_pa=complex(zeros(degree_pa*memorylen_pa,1));
%% Compute input scaling factor with overrange
% and scale raw input accordingly 
u = pa_in(toss+1:(traininglen+pad)); % select data and transpose
umax_inv = 1/(max(abs(u)));   
umax_inv = 1;
u = u*umax_inv; 
v = pa_out(toss+1:(traininglen+pad)); % select data  
% Normalize output data to the maximum data. Needed
% to make numeric algorithms work. Note that this step might cause problems
% if there is outlying data OR if one does not account for this scaling.
vmax_inv = 1/(max(abs(v)));  
%vmax_inv = 1;
v = v*vmax_inv;
% In general there is no point in deriving the PA model since we
% are not implementing it. Sometimes you may only have PA
% measurements however and from those you wish to simulate the PA
% in the time domain. You can in that case derive a PA model
% but keep in mind it may not be an excellent model if you're
% PA is predominantly IIR in nature. This is true since the 
% memory polynomial assumes an FIR model. An FIR filter is great for
% equalizing the effects of an IIR filter but not necessarily great at 
% modeling it. What we have found experimentially is that if you have 
% an IIR-dominant PA, then you can model the passband quite effectively with this technique
% but the stopband may suffer particularly when there is significant
% dynamic range, i.e. a lot of attenuation in the stop band.
if 0
    offset = 0;
    up = u(1:end-offset);
    vp = v(1+offset:end);
    % Compute PA model coefficients. 
    coef_pa   = fit_memory_poly_model(up, vp, traininglen, memorylen_pa, degree_pa);   

    figure;plot([1:length(coef_pa)],real(coef_pa),'r+-',[1:length(coef_pa)],imag(coef_pa),'b+-');grid
    title('PA coefficients');
end

if 1
% Compute DPD Algorithm Coefficients using reversed I/O's
% Adding delay to the output variable (v) was crucial in using this memory
% polynomial based derivation of the DPD. We delay the output
% to compensate for the delay inherent in the PA. 
% You must take your PA's particular delay into account. The input and output 
% are reversed for the DPD derivation. v is now the input and u is the output. By setting
% vp = v(1+offset:end) we are compensating for the delay in the PA. 
% Essentially we are making it appear that the output responds to the
% input "offset" samples earlier, non-causal ish.
% You can create this effective negative delay in the DPD coefficient 
% derivation using this "offset" varible. It is not
% necessary to get the offset value perfect. There is a range of acceptable
% values for offset. You simply need to capture the energy within the M taps you're
% alloted. One informal offset calibration procedure is to observe the derived
% DPD coefficients as you change "offset" by 1. You should see the DPD coeffs
% shift by 1 as well. If you notice an uncorrelated change in the DPD coefficients 
% then you're offset value needs correction. In some cases you may also
% need to make M larger if you're PA has multiple poles you're trying to
% compensate for. Ideally, place the largest tap in the center of your
% pipeline. So if M = 5, place the largest tap at 3 using "offset" as the
% tuning parameter. This gives you some slop on both sides in case the
% PA delay were to change a little.
offset = 3;
up = u(1:end-offset);
vp = v(1+offset:end);
coef_pd  = fit_memory_poly_model(vp, up, traininglen, memorylen_pd, degree_pd);

figure;plot([1:length(coef_pd)],real(coef_pd),'ro-',[1:length(coef_pd)],imag(coef_pd),'bo-');grid
title('DPD coefficients');
legend('real','imag');

end

tfit = toc