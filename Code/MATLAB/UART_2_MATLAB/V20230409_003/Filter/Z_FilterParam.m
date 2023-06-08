% 2023.04.01
% This subscript is to identify the paramters for the real time filter by
% using filter designer in MATLAB.

clear all; clc; close all;
filterDesigner;
% Selection
% Response Type: Lowpass
% Design Method: IIR: Butterworth
% Filter Order: 8
% Frequency Specifications:
% Unit: Hz
% Fs (sampling rate/frequency): system.Hz=112
% Fc (cut off frequency): 40.4 Hz for theta_dot, 38.38 Hz for phi_dot
% Enjoy~

