% 2023.04.11
% This subscript is to set the communication between MATLAB (or PC) and
% Arduino board, the function is to realize sending arm_states to Arduino
% and read the human_states from Arduino at the same time.

fopen(system.human.port);
while system.toggle==1
    fprintf(system.human.port,'%s',char('a'));
end
fclose(system.human.port);

