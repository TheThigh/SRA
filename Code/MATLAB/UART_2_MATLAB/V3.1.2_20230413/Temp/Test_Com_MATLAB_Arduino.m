% 2023.04.13
% This subscript is to test if the configureCallback function will truly be
% called especially for the communication between and Arduino board and
% MATLAB.


clear all; clc; close all;
% global system;
% system.human.record=[];
% system.human.port=serialport("COM6",115200);
% configureCallback(system.human.port,"terminator",@readSerialData);
% 
% pause;
% configureCallback(system.human.port,"off");
%     flush(system.human.port);
%     delete(system.human.port);


b=serialport("COM6",115200);

toggle=1;
k=0;

    for i=1:1000
        k=k+1;
        writeline(b,string(k));
        data=readline(b);
        disp(data);
    end

% configureCallback(b,'termonator',@readSerialData);
% 
% 
% pause;
% configureCallback(b,"off");
% flush(b);
% delete(b);

