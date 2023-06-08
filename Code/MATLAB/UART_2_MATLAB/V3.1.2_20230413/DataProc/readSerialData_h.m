function readSerialData_h(eu_ang,~)

global system;
if system.toggle==0
    configureCallback(system.human.port,"off");
    flush(system.human.port);
    delete(system.human.port);
else

%     data=readline(eu_ang);
% 
%     system.human.record=[system.human.record;data];
    system.states.instant=[];
    if isfield(system,'arm')
        for i=1:length(system.devices.arm.info.com)
            system.states.instant=[system.states.instant system.arm(i).record(end,:)];
        end
%         fprintf(system.human.port,'%s',system.states.instant);
 
    end
    writeline(system.human.port,system.states.instant);
    data=readline(eu_ang);
    display(data);
    fprintf(['wdnmd','\n']);
%     disp(system.states.instant);
% disp(datestr(now));
end

end


