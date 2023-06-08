function readSerialData_b(quat,~)

global system;
if system.toggle==0
    configureCallback(system.base.port,"off");
    flush(system.base.port);
    delete(system.base.port);
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
    system.base.quatNo=quatNo;
    
%     disp(system.base.quatNo);

end

end


