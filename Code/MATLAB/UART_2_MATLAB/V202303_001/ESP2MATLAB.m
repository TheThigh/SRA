% 2023.03.07
% This subscript is to realize the communication between ESP and MATLAB,
% actually the communication between any serial port stream to MATLAB. The
% background is that we can directly read stream data from MATLAB through
% Arduino board, but ESP no.

%% %%%%%%%% %%
% Use this following line of code to terminate the data reading.

% for i=1:system.no   configureCallback(system.arm(i).port,"off");   end
% configureCallback(system.base.port,"off");

%% %%%%%%%% %%

clear all; clc; close all;
% The following line of code is to release the resource.
delete(instrfindall);
warning('off','all');

global system;

YourHeart=[]; % To trigger a infinite loop.
system.no=1; % The number of arms
system.Hz=112;
if isempty(serialportlist("available"))
    fprintf(['   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n',...
        '   There are no devices connected to the PC currently, please make a double check.','\n',...
        '   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n']);
else
    system.toggle=1; % This string is to stop the commnication without pulling out any devices. 1=on, 0=off.
    if length(serialportlist("available"))==4
        system.Arduino.port=arduino("COMn","Mega2560"); % The specific port number should be identified.
        fopen(system.Arduino.port);
    end
    system.arm(1).port=serialport("COM1",115200);
    % system.arm(2).port=serialport("COM7",115200);
    
    % To make sure the serial data from IMUs can be sent into Arduino to
    % realize the final control, we need to define the serial port in the
    % system struct as well (global variable) to avoid the issue that the
    % single serial port will be occupied.
    
    % 2023.03.08
    % Temporarily we do not have the data from IMU mounted on the base of the
    % backpack, so we just take the arm2 data for a test.
    system.base.port=serialport("COM2",115200);
    
    for i=1:system.no
        set(system.arm(i).port,'inputBufferSize',1024000);
        set(system.arm(i).port,'outputBufferSize',1024000);
        system.arm(i).record=[];
        system.arm(i).peak=[];

        % Filter design to eliminate the noise for angular velocity
        % computation.
        system.arm(i).filter.phi_dot0=0; % initial velocity when starting up
        system.arm(i).filter.Q=1e-3; % variance of prediction
        system.arm(i).filter.R=0.36; % variance of sensor measurement
        system.arm(i).filter.P_kalman=2; % initial estimated variance
        system.arm(i).filter.phi_dot_kalman=0;


    end
    set(system.base.port,'inputBufferSize',1024000);
    set(system.base.port,'outputBufferSize',1024000);

    % Initialization
    % system.arm(1).quatNo=zeros(1,4);
    % system.arm(2).quatNo=zeros(1,4);
    % system.base.quatNo=zeros(1,4);
    
    % Temporarily to make sure the return value will not be over written by
    % that with exactly the same name of variable, we need to set up different functions.
    
    % To make sure the callback data of the base IMU is not empty, the function
    % of base should be executed firstly.
    configureCallback(system.base.port,"terminator",@readSerialData_b);
    configureCallback(system.arm(1).port,"terminator",@readSerialData_a1);
    if system.no==2
        configureCallback(system.arm(2).port,"terminator",@readSerialData_a2);
    end

    % 2023.03.09
    % Stop trigger of the procedure
    system.toggle=input(['   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -' ...
        ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n',...
        '   You can type "0" in the command window',...
        ' to stop the procedure whenever you need.','\n'...
        '   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -' ...
        ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n']);
    clc;
    while isempty(YourHeart)
        if system.toggle==1
            system.toggle=input(['   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',...
                ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n',...
                '   The procedure will be continued, you still can stop it at any time you want',...
                ' by inserting "0".','\n',...
                '   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',...
                ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n']);
            clc;
        elseif isempty(system.toggle)||(system.toggle~=0&&system.toggle~=1)
            system.toggle=1;
            system.toggle=input(['   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'...
                ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n',...
                '   Your input is neither "0" nor "1", the procedure will be deemed to be continued'...,
                ' by the system.','\n',...
                '   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'...
                ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n']);
            clc;
        end
        if system.toggle==0
            fprintf(['   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n',...
                '   The serial port communication is ended.','\n',...
                '   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n']);
            break;
        end
    end
    system.date=datestr(now);
    system.date=replace(system.date,'-','_');
    system.date=replace(system.date,':','_');
    system.date=replace(system.date,' ','_');
    system.arm_states=[system.arm(1).record];
    if system.no>1
        for i=1:system.no-1
            system.arm_states=[system.arm_states system.arm(i+1).record];
        end
    end
%     states=system.arm_states;
%     save(['Results/','arm_states_',system.date,'.txt'],'states','-ascii');
%     save(['Results/','system_',system.date,'.mat'],'system');

    % Plot
    for i=1:system.no
        system.arm(i).step=length(system.arm(i).record);
        for j=1:system.arm(i).step
            system.arm(i).t(j)=1/system.Hz*j;
        end
        figure(i);
        subplot(1,2,1);
        plot(system.arm(i).t,system.arm(i).record(:,1),'r','linewidth',1);
        hold on; axis on; grid on;
        plot(system.arm(i).t,system.arm(i).record(:,2),'b','linewidth',1);
        xlabel('Time (s)'); ylabel('Angle (rad)');
        legend('\theta','\phi');
        subplot(1,2,2);
        plot(system.arm(i).t,system.arm(i).record(:,3),'r','linewidth',1);
        hold on; axis on; grid on;
        plot(system.arm(i).t,system.arm(i).record(:,4),'b','linewidth',1);
        xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
        legend({'$\dot{\theta}$','$\dot{\phi}$'},'interpreter','latex');
        % Add a super title to the subplot
        % The function suptitle was eliminated from version 2018, now we
        % need to use sgtitle (subplot grid title) instead.
        sgtitle(['Arm ',num2str(i)]);
        set(gcf,'position',[50,250,1000,400]);
    end
    clear i; clear j; clear states;
    
end
clear YourHeart;


