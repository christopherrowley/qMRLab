function [rf_pulse, omega1, A_t, Params] = Hanning_pulse( Trf, Params)

%   Hanning_pulse Adiabatic Hanning RF pulse function.
%   pulse = GaussC_pulse(Trf, PulseOpt)
%
%   B1(t) = A(t) * exp( -1i *integral(omega1(t')) dt' )
%   where A(t) is the envelope, omega1 is the frequency sweep
%
%   Phase modulation is found from taking the integral of omega1(t)
%   Frequency modulation is time derivative of phi(t)
%
%   For the case of a Gauus^c pulse:
%   A(t) = A_0 * ((1 + cos(pi*t))/2)
%   omega1(t) = t + ((4/3)*pi)*sin(pi*t) * (1 + 1/4*cos(pi*t))
%   A0 is the peak amplitude in microTesla
%
%   The pulse is defined to be 0 outside the pulse window (before 
%   t = 0 or after t=Trf). (HSn, n = 1-8+) 
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Duration of the RF pulse in seconds.
%
%   --optional args--
%   PulseOpt: Struct. Contains optional parameters for pulse shapes.
% 
%   Reference: Matt A. Bernstein, Kevin F. Kink and Xiaohong Joe Zhou.
%              Handbook of MRI Pulse Sequences, pp. 110, Eq. 4.10, (2004)
%
%              Tannús, A. and M. Garwood (1997). "Adiabatic pulses." 
%              NMR in Biomedicine 10(8): 423-434.
%
%
% To be used with qMRlab
% Written by Christopher Rowley 2023 & Amie Demmans 2024


% Function to fill default values;
Params.PulseOpt = defaultHanningParams(Params.PulseOpt);

nSamples = Params.PulseOpt.nSamples;  
t = linspace(0, Trf, nSamples);
%tau = ((2*t/Trf)-1);
tau = t-Trf/2;

% Amplitude
%A_t = Params.PulseOpt.A0*((1+cos(tau.*pi))./2);
A_t = Params.PulseOpt.A0*((1+cos(pi.*tau.*Params.PulseOpt.beta))./2);
    % From ref 2 but with addition of beta term 
A_t((t < 0 | t>Trf)) = 0;
% disp( ['Average B1 of the pulse is:', num2str(mean(A_t))]) 

% Scaling Factor 
lambda = (Params.PulseOpt.A0)^2 ./ (Params.PulseOpt.beta.*Params.PulseOpt.Q);

% Carrier frequency modulation function w(t):
    % Integral of A_t^2
omegaterm1 = Params.PulseOpt.beta.*tau;
omegaterm2 = (4/(3*pi)*sin(pi.*tau.*Params.PulseOpt.beta));
omegaterm3 = 1+1/4*cos(pi.*tau.*Params.PulseOpt.beta);
omega1 = -lambda.*(omegaterm1+(omegaterm2.*omegaterm3));


% Phase modulation function phi(t):
phiterm1 = (Params.PulseOpt.beta*lambda.*tau.^2)./2;
phiterm2num = lambda*(cos(pi.*tau.*Params.PulseOpt.beta)+4).^2;
phiterm2denom = 6*Params.PulseOpt.beta*pi^2;
phi = phiterm1 - (phiterm2num/phiterm2denom);

% Put together complex RF pulse waveform:
rf_pulse = A_t .* exp(1i .* phi);







