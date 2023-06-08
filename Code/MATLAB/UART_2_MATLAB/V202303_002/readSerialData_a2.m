function readSerialData_a2(quat,~)

global system;
if system.toggle==0
    configureCallback(system.arm(2).port,"off");
    delete(system.arm(2).port);
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
    
    for j=1:lm
        p_minus(j)=round((p_minus(j)-1)/7);
        quatNo(1,p_minus(j)+1)=-quatNo(1,p_minus(j)+1);
    end
    system.arm(2).quatNo=quatNo;
    
    system.arm(2).theta=acos((2*(system.base.quatNo(1))^2+...
        2*(system.base.quatNo(4))^2-1)*...
        (2*(system.arm(2).quatNo(1))^2+2*(system.arm(2).quatNo(4))^2-1)+...
        (2*system.base.quatNo(1)*system.base.quatNo(2)+...
        2*system.base.quatNo(3)*system.base.quatNo(4))*...
        (2*system.arm(2).quatNo(1)*system.arm(2).quatNo(2)+...
        2*system.arm(2).quatNo(3)*system.arm(2).quatNo(4))+...
        (2*system.base.quatNo(1)*system.base.quatNo(3)-...
        2*system.base.quatNo(2)*system.base.quatNo(4))*...
        (2*system.arm(2).quatNo(1)*system.arm(2).quatNo(3)-...
        2*system.arm(2).quatNo(2)*system.arm(2).quatNo(4)));
    
    system.arm(2).phi=atan2((2*system.arm(2).quatNo(1)*system.arm(2).quatNo(2)+...
        2*system.arm(2).quatNo(3)*system.arm(2).quatNo(4))*...
        (2*(system.base.quatNo(1))^2+2*(system.base.quatNo(3))^2-1)-...
        (2*(system.base.quatNo(1))*(system.base.quatNo(2))-...
        2*(system.base.quatNo(3))*(system.base.quatNo(4)))*...
        (2*(system.arm(2).quatNo(1))^2+2*(system.arm(2).quatNo(4))^2-1)-...
        (2*system.base.quatNo(1)*system.base.quatNo(4)+...
        2*system.base.quatNo(2)*system.base.quatNo(3))*...
        (2*system.arm(2).quatNo(1)*system.arm(2).quatNo(3)-...
        2*system.arm(2).quatNo(2)*system.arm(2).quatNo(4)),...
        (2*system.base.quatNo(1)*system.base.quatNo(3)+...
        2*system.base.quatNo(2)*system.base.quatNo(4))*...
        (2*(system.arm(2).quatNo(1))^2+2*(system.arm(2).quatNo(4))^2-1)-...
        (2*system.arm(2).quatNo(1)*system.arm(2).quatNo(3)-...
        2*system.arm(2).quatNo(2)*system.arm(2).quatNo(4))*...
        (2*(system.base.quatNo(1))^2+2*(system.base.quatNo(2))^2-1)-...
        (2*system.base.quatNo(1)*system.base.quatNo(4)-...
        2*system.base.quatNo(2)*system.base.quatNo(3))*...
        (2*system.arm(2).quatNo(1)*system.arm(2).quatNo(2)+...
        2*system.arm(2).quatNo(3)*system.arm(2).quatNo(4)));
    
    system.arm(2).theta=real(system.arm(2).theta);
    system.arm(2).phi=real(system.arm(2).phi);

    system.arm(2).phi=system.arm(2).phi-2*pi*floor(system.arm(2).phi/(2*pi));

    if isempty(system.arm(2).record)==0
        if abs(system.arm(2).record(end,2)-system.arm(2).phi)>=6 % To judge if the angle change is 2*pi
            if system.arm(2).record(end,2)>=6
                system.arm(2).phi_dot=(system.arm(2).phi+2*pi-system.arm(2).record(end,2))/(1/system.Hz);
            elseif system.arm(2).phi>=6
                system.arm(2).phi_dot=(system.arm(2).phi-(2*pi+system.arm(2).record(end,2)))/(1/system.Hz);
            end
        else
            system.arm(2).theta_dot=(system.arm(2).theta-system.arm(2).record(end,1))/(1/system.Hz);
            system.arm(2).phi_dot=(system.arm(2).phi-system.arm(2).record(end,2))/(1/system.Hz);
        end
        
        if length(system.mode)==length('perfect')&&(length(system.arm(2).record))/system.Hz>10
            system.arm(2).temp.theta_dot=Z_doFilter_theta([system.arm(2).record(:,3);system.arm(2).theta_dot]);
            system.arm(2).temp.phi_dot=Z_doFilter_phi([system.arm(2).record(10*system.Hz:end,4);system.arm(2).phi_dot]);
            system.arm(2).theta_dot=system.arm(2).temp.theta_dot(end);
            system.arm(2).phi_dot=system.arm(2).temp.phi_dot(end);
        end
        
    else
        system.arm(2).theta_dot=0;
        system.arm(2).phi_dot=0;
    end
    system.arm(2).record=[system.arm(2).record;system.arm(2).theta system.arm(2).phi ...
        system.arm(2).theta_dot system.arm(2).phi_dot];
    
%     disp([system.arm(2).theta system.arm(2).phi ...
%         system.arm(2).theta_dot system.arm(2).phi_dot]);

    if isfield(system,'Arduino')
        fprintf(system.Arduino.port,system.arm(2).record);
    end

end

end


