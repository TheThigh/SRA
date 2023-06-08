% 2023.03.08
% The data can be read directly from IMUs are quaterions rather than
% angles.

function readSerialData_a1(quat,~)

global system;
if system.toggle==0
    configureCallback(system.arm(1).port,"off");
    flush(system.arm(1).port);
    delete(system.arm(1).port);
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

    % 2023.06.07
    % The following lines of code will make the procedure not be terminated
    % timely with at least 10 mins' lag, the reason behind is still being
    % investigated.

%     if system.human.temp.ti~=-1
%         system.human.temp.ti=toc(system.human.temp.t0);
%     end
%     if isempty(system.human.record)&&system.human.temp.ti>20
%         cprintf('*err',['   ! ! ! WARNING: Human data has not been recorded ! ! !','\n']);
%         system.human.temp.ti=-1;
%     end
    
%     disp([system.arm(1).theta system.arm(1).phi ...
%         system.arm(1).theta_dot system.arm(1).phi_dot]);

    if isfield(system,'human')&&system.controller==1

        system.states.instant.num=[];
        for i=1:length(system.arm)
            for j=1:length(system.devices.history)
                if contains(system.devices.history{j},system.devices.arm.info.com{i})
                    arm_info=system.devices.history{j};
                    arm_ord=str2num(arm_info(5));
                    % Since temporarily I haven't found any proper way to
                    % pass struct data from MATLAB to Arduino, we should
                    % let Arduino know the arm order of these data.
                    system.states.instant.num=[system.states.instant.num arm_ord system.arm(arm_ord).record(end,:)];
                end
            end
        end

        % 2023.04.14
        % The example test code shown as follows didn't work when being
        % added after the writeline code, which means that the procedure
        % was not executed for some reasons, maybe because the output
        % format cannot be recognized by Arduino?
        % Example test code:
%         [r_record,~]=size(system.arm(1).record);
%         fprintf([num2str(r_record),'\n']);
        
        [~,c_instant]=size(system.states.instant.num);
        system.states.instant.str=[];
        for i=1:c_instant
            if i==1
                system.states.instant.str=num2str(system.states.instant.num(i));
            else
            system.states.instant.str=[[system.states.instant.str,' '],num2str(system.states.instant.num(i))];
            end
        end

        % The stream data needs to be sent to Arduino has to be a scalar
        % string rather than any other classes like int or double.

        writeline(system.human.port,(system.states.instant.str));
%         disp(system.states.instant.str);

        human_data=readline(system.human.port);
%         disp(human_data);

    end

end

end


