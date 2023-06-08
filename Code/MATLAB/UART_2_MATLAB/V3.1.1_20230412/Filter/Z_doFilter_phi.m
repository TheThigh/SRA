function y = doFilter(x)
%DOFILTER Filters input x and returns output y.

% MATLAB Code
% Generated by MATLAB(R) 9.12 and DSP System Toolbox 9.14.
% Generated on: 02-Apr-2023 04:49:30

%#codegen

% To generate C/C++ code from this function use the codegen command.
% Type 'help codegen' for more information.

persistent Hd;

if isempty(Hd)
    
    % The following code was used to design the filter coefficients:
    %
    % N    = 8;      % Order
    % F3dB = 38.38;  % 3-dB Frequency
    % Fs   = 112;    % Sampling Frequency
    %
    % h = fdesign.lowpass('n,f3db', N, F3dB, Fs);
    %
    % Hd = design(h, 'butter', ...
    %     'SystemObject', true);
    
    Hd = dsp.BiquadFilter( ...
        'Structure', 'Direct form II', ...
        'SOSMatrix', [1 2 1 1 0.945812093283252 0.719782657653733; 1 2 1 1 ...
        0.751308133898407 0.366113531861677; 1 2 1 1 0.649136717292492 ...
        0.180333891661893; 1 2 1 1 0.604636670682013 0.0994188674525703], ...
        'ScaleValues', [0.666398687734246; 0.529355416440021; ...
        0.457367652238596; 0.426013884533646; 1]);
end

s = double(x);
y = step(Hd,s);
