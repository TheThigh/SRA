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
    
    % The logic to add a minus sign before the calibrated data is that for
    % each character number, the maximum length of the string will be 7, if
    % we deivide the location of each minus sign by 7, and round it, the
    % result will be the No. of the data should be added with a minus sign.
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
    if isempty(system.arm(2).record)==0
        
        if system.arm(2).phi<0&&system.arm(2).record(end,2)>0
            if isempty(system.arm(1).peak)
                system.arm(2).peak=system.arm(2).record(end,2);
            end
            system.arm(2).phi=2*system.arm(2).peak+system.arm(2).phi;
        elseif ~isempty(system.arm(2).peak)&&system.arm(2).phi>=0
            system.arm(2).peak=[];
        end

        system.arm(2).theta_dot=(system.arm(2).theta-system.arm(2).record(end,1))/(1/system.Hz);
        system.arm(2).phi_dot=(system.arm(2).phi-system.arm(2).record(end,2))/(1/system.Hz);
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


