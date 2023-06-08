% 2023.03.08
% The data can be read directly from IMUs are quaterions rather than
% angles.

function readSerialData_a1(quat,~)

global system;
if system.toggle==0
    configureCallback(system.arm(1).port,"off");
    flush(system.arm(1).port);
    delete(system.arm(1).port);
    if isfield(system,'Arduino')
        fclose(system.Arduino.port);
        delete(system.Arduino.port);
    end
else
    data = readline(quat);
    pat=digitsPattern; % This parameter will be used to find the digits in the original outputs.
    quatNo=zeros(1,4); % Record the intermediate quaternions.
    digits=extract(data,pat);
    for i=1:4
        quatNo(1,i)=str2double(strcat(digits(2*i-1),'.',digits(2*i)));
    end
    p_minus=strfind(data,"-");
    lm=length(p_minus);
    
    % The logic to add a minus sign before the calibrated data is that for
    % each character number, the maximum length of the string will be 7, if
    % we deivide the location of each minus sign by 7, and round it, the
    % result will be the No. of the data should be added with a minus sign.
    for j=1:lm
        p_minus(j)=round((p_minus(j)-1)/7);
        quatNo(1,p_minus(j)+1)=-quatNo(1,p_minus(j)+1);
    end
    system.arm(1).quatNo=quatNo;
    
    system.arm(1).theta=acos((2*(system.base.quatNo(1))^2+...
        2*(system.base.quatNo(4))^2-1)*...
        (2*(system.arm(1).quatNo(1))^2+2*(system.arm(1).quatNo(4))^2-1)+...
        (2*system.base.quatNo(1)*system.base.quatNo(2)+...
        2*system.base.quatNo(3)*system.base.quatNo(4))*...
        (2*system.arm(1).quatNo(1)*system.arm(1).quatNo(2)+...
        2*system.arm(1).quatNo(3)*system.arm(1).quatNo(4))+...
        (2*system.base.quatNo(1)*system.base.quatNo(3)-...
        2*system.base.quatNo(2)*system.base.quatNo(4))*...
        (2*system.arm(1).quatNo(1)*system.arm(1).quatNo(3)-...
        2*system.arm(1).quatNo(2)*system.arm(1).quatNo(4)));
    
    system.arm(1).phi=atan2((2*system.arm(1).quatNo(1)*system.arm(1).quatNo(2)+...
        2*system.arm(1).quatNo(3)*system.arm(1).quatNo(4))*...
        (2*(system.base.quatNo(1))^2+2*(system.base.quatNo(3))^2-1)-...
        (2*(system.base.quatNo(1))*(system.base.quatNo(2))-...
        2*(system.base.quatNo(3))*(system.base.quatNo(4)))*...
        (2*(system.arm(1).quatNo(1))^2+2*(system.arm(1).quatNo(4))^2-1)-...
        (2*system.base.quatNo(1)*system.base.quatNo(4)+...
        2*system.base.quatNo(2)*system.base.quatNo(3))*...
        (2*system.arm(1).quatNo(1)*system.arm(1).quatNo(3)-...
        2*system.arm(1).quatNo(2)*system.arm(1).quatNo(4)),...
        (2*system.base.quatNo(1)*system.base.quatNo(3)+...
        2*system.base.quatNo(2)*system.base.quatNo(4))*...
        (2*(system.arm(1).quatNo(1))^2+2*(system.arm(1).quatNo(4))^2-1)-...
        (2*system.arm(1).quatNo(1)*system.arm(1).quatNo(3)-...
        2*system.arm(1).quatNo(2)*system.arm(1).quatNo(4))*...
        (2*(system.base.quatNo(1))^2+2*(system.base.quatNo(2))^2-1)-...
        (2*system.base.quatNo(1)*system.base.quatNo(4)-...
        2*system.base.quatNo(2)*system.base.quatNo(3))*...
        (2*system.arm(1).quatNo(1)*system.arm(1).quatNo(2)+...
        2*system.arm(1).quatNo(3)*system.arm(1).quatNo(4)));
    
    system.arm(1).theta=real(system.arm(1).theta);
    system.arm(1).phi=real(system.arm(1).phi);
    
    system.arm(1).phi=system.arm(1).phi-2*pi*floor(system.arm(1).phi/(2*pi));

    if isempty(system.arm(1).record)==0
        if abs(system.arm(1).record(end,2)-system.arm(1).phi)>=6 % To judge if the angle change is 2*pi
            if system.arm(1).record(end,2)>=6
                system.arm(1).phi_dot=(system.arm(1).phi+2*pi-system.arm(1).record(end,2))/(1/system.Hz);
            elseif system.arm(1).phi>=6
                system.arm(1).phi_dot=(system.arm(1).phi-(2*pi+system.arm(1).record(end,2)))/(1/system.Hz);
            end
        else
            system.arm(1).theta_dot=(system.arm(1).theta-system.arm(1).record(end,1))/(1/system.Hz);
            system.arm(1).phi_dot=(system.arm(1).phi-system.arm(1).record(end,2))/(1/system.Hz);
        end

        %% Filter Design %%
        % The aim of the filter is not to perfectly eliminate all the noise,
        % just to decrease it to the greatest extent.
        
        if length(system.mode)==length('perfect')&&(length(system.arm(1).record))/system.Hz>10
            system.arm(1).temp.theta_dot=Z_doFilter_theta([system.arm(1).record(:,3);system.arm(1).theta_dot]);
            system.arm(1).temp.phi_dot=Z_doFilter_phi([system.arm(1).record(10*system.Hz:end,4);system.arm(1).phi_dot]);
            system.arm(1).theta_dot=system.arm(1).temp.theta_dot(end);
            system.arm(1).phi_dot=system.arm(1).temp.phi_dot(end);
        end

        %% %%%%%% %%

    else
        system.arm(1).theta_dot=0;
        system.arm(1).phi_dot=0;
    end

    system.arm(1).record=[system.arm(1).record;system.arm(1).theta system.arm(1).phi ...
        system.arm(1).theta_dot system.arm(1).phi_dot];
    
    disp([system.arm(1).theta system.arm(1).phi ...
        system.arm(1).theta_dot system.arm(1).phi_dot]);
    
    % Realize the communication between MATLAB and Arduino, in the
    % direction of MATLAB → Arduino.
    if isfield(system,'Arduino')
        fprintf(system.Arduino.port,system.arm(1).record);
    end

end

end


