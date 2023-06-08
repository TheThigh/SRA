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
    
    % 2023.03.09
    % Given the situation that in at some the points in the 3D space the
    % returned angle using the formula above will be a complex number, after
    % looking up some background knowledge, it turns out to be the limitation
    % of trigonometric functions and the accuracy of IMUs maybe, the accepted
    % range of acos function in MATLAB is [-1,1], any value exceeding this
    % range will cause a complex number result, it usually occurs at 0 and pi,
    % all we need to do is just to eliminate the imaginary part.
    
    system.arm(1).theta=real(system.arm(1).theta);
    system.arm(1).phi=real(system.arm(1).phi);

    % 2023.03.27
    % Manu's algorithm, it works, and it is the same as the MATLAB's own
    % function wrapTo2Pi.
    system.arm(1).phi=system.arm(1).phi-2*pi*floor(system.arm(1).phi/(2*pi));
    
    % The limitation of using function wrapTo2Pi is that the angle at the very
    % beginning can be extremely large.
    % system.arm(1).phi=wrapTo2Pi(system.arm(1).phi);

    % 2023.03.17
    % The following lines of code are to eliminate the error caused by phi
    % angle data collection, the issue is that when the phi exceeds pi, it
    % will directly become negative value, which makes this process not
    % continuous.

    if isempty(system.arm(1).record)==0
        % We just need to compare the value with 3 rather than exact pi
        % becasue sometimes the negative values will emerge before the
        % angle reach pi.
        %% 2023.03.20 %%
        % 0 is better than 3.
        
        % Update Notes
        % 2023.03.27
        % The limitation of my codes is it cannot deal with the angle
        % change from 0 to 2*pi, it will still cause some negative values.
        % And the notes will be deleted in the next coming version.

%         if system.arm(1).phi<0&&system.arm(1).record(end,2)>0
%             if isempty(system.arm(1).peak)
%                 system.arm(1).peak=system.arm(1).record(end,2);
%             end
%             system.arm(1).phi=2*system.arm(1).peak+system.arm(1).phi;
%         elseif ~isempty(system.arm(1).peak)&&system.arm(1).phi>=0
%             system.arm(1).peak=[];
%         end

        %% %%%%%% %%

        system.arm(1).theta_dot=(system.arm(1).theta-system.arm(1).record(end,1))/(1/system.Hz);
        system.arm(1).phi_dot=(system.arm(1).phi-system.arm(1).record(end,2))/(1/system.Hz);

        % Kalman Filter
%         system.arm(1).filter.phi_dot_pre=system.arm(1).filter.phi_dot_kalman;
%         system.arm(1).filter.P_pre=system.arm(1).filter.P_kalman+system.arm(1).filter.Q;
%         system.arm(1).filter.K=system.arm(1).filter.P_kalman/(system.arm(1).filter.P_kalman+system.arm(1).filter.R);
%         system.arm(1).filter.phi_dot=system.arm(1).filter.phi_dot_pre+system.arm(1).filter.K*...
%             (system.arm(1).phi_dot-system.arm(1).filter.phi_dot_pre);
%         system.arm(1).filter.P_kalman=system.arm(1).filter.P_pre-system.arm(1).filter.K*system.arm(1).filter.P;
        
%         system.arm(1).theta_dot=system.arm(1).intm.theta_dot(end);
%         system.arm(1).phi_dot=system.arm(1).intm.phi_dot(end);

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


