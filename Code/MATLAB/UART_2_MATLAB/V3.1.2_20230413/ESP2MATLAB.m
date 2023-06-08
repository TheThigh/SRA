% 2023.03.07
% This subscript is to realize the communication between ESP and MATLAB,
% actually the communication between any serial port stream to MATLAB. The
% background is that we can directly read stream data from MATLAB through
% Arduino board, but ESP no.

%% %%%%%%%% %%
% Use this following line of code to terminate the data reading.

% for i=1:length(system.devices.arm.info.com)   configureCallback(system.arm(i).port,"off");   end
% configureCallback(system.base.port,"off");

%% %%%%%%%% %%

clear all; clc; close all;
addpath('.\Results'); addpath('.\DarkTech');
% The following line of code is to release the resource.
delete(instrfindall);
warning('off','all');
temp.file.info=dir('.');
temp.file.path={temp.file.info.folder}';
temp.file.name={temp.file.info.name}';
if ~isempty(strfind(temp.file.name,'DarkTech'))&&~isempty(strfind(temp.file.name,'DataProc'))&&...
        ~isempty(strfind(temp.file.name,'Filter'))&&~isempty(strfind(temp.file.name,'Results'))
    temp.mfile.path=temp.file.path{1};
    temp=FindLatestFile(temp);
    if ~isempty(temp.matfile.list)
        load(temp.matfile.target.name);
        temp.devices=system.devices;
    end
    clear system;
    % 2023.04.10
    % Serious bug fixed: because when being assigned the value from system
    % to temp, all the port information will also be transmitted to it,
    % that's the reason why some of the ports will be occupied all the
    % time, so we shall need to delete all the port information once more.
    % - - - No need.
%     delete(instrfindall);
else
    temp.interface.indication='   The main subscript in the current folder is missing, procedure is terminated.';
    temp.interface.length=strlength(temp.interface.indication);
    temp.interface.cutoff='   -';
    temp.interface.golden_ratio=8/11;
    for i=1:ceil((temp.interface.length-3)*temp.interface.golden_ratio)
        temp.interface.cutoff=strcat(temp.interface.cutoff,' -');
    end
    fprintf([temp.interface.cutoff,'\n',temp.interface.indication,'\n',temp.interface.cutoff,'\n']);
    return;
end

global system;

YourHeart=[]; % To trigger a infinite loop.
system.Hz=112;
system.mode='perfect';
% 'authentic': keep all the original data;
% 'perfect': filter noise for the angular velocity and filter out the
% initialization process before 10 s and reset the starting time.

system.devices.MATLAB.info=version;
system.devices.MATLAB.v=system.devices.MATLAB.info(strfind(system.devices.MATLAB.info,'R')+1:strfind(system.devices.MATLAB.info,'R')+4);
system.devices.MATLAB.v=str2num(system.devices.MATLAB.v);
[~,system.devices.PC.ram]=memory;
system.devices.PC.ram=system.devices.PC.ram.PhysicalMemory.Total/1024^3;
system.interface.golden_ratio=8/11;
[MAC,~]=MACAddress();

% 2023.04.05
% Sometimes the information stored in the second column of the returned
% cell cannot correctly correspond the port No. currently being occupied,
% so we're going to make some aftertreatment.



%%      Set Up Section      %%
if ~isfield(temp.devices,'PC')||string(MAC)~=string(temp.devices.PC.mac)
    system.interface.indication='   This is probably the first time you are testing on this PC or key information of hardware has not been recorded ';
    system.interface.length=strlength(system.interface.indication);
    system.interface.cutoff='   -';
    for i=1:ceil((system.interface.length-3)*system.interface.golden_ratio)
        system.interface.cutoff=strcat(system.interface.cutoff,' -');
    end
    system.interface.indication=['   This is probably the first time you are testing on this PC or key information of hardware has not been recorded ',...
        '\n','   properly in the previous test, please follow the steps below to finish the set up.','\n',...
        system.interface.cutoff,'\n',...
        '   Step 1:','\n',...
        '   Please plug in the *Base Global Coordinate ONLY* first, after doing this, please press any key to continue.'];
    fprintf([system.interface.cutoff,'\n',system.interface.indication,'\n',system.interface.cutoff,'\n']);
    pause;
    clc;
    system.devices.info=UARTDevicesFunc();
    [system.devices.no,~]=size(system.devices.info);
    if system.devices.no==1&&isempty(strfind(system.devices.info{1,1},'Arduino'))
        system.devices.base.info.UART=system.devices.info{1,1};
        system.devices.base.info.com=strfind(system.devices.base.info.UART,'COM');
        system.devices.base.info.port=string(system.devices.base.info.UART(system.devices.base.info.com:end-1));
        system.base.port=serialport(system.devices.base.info.port,115200);
        % Only if the connection between the base coordiante IMU and PC is set
        % up, the MAC address will be recorded.
        [system.devices.PC.mac,~]=MACAddress();
        system.interface.indication='   Now you can plug in any other electronics, press any key to continue when you finish.';
        system.interface.length=strlength(system.interface.indication);
        system.interface.cutoff='   -';
        for i=1:ceil((system.interface.length-3)*system.interface.golden_ratio)
            system.interface.cutoff=strcat(system.interface.cutoff,' -');
        end
        system.interface.indication=['   Step 2:','\n',...
            '   Now you can plug in any other electronics, press any key to continue when you finish.'];
        fprintf([system.interface.cutoff,'\n',system.interface.indication,'\n',system.interface.cutoff,'\n']);
        pause;
        clc;
    elseif system.devices.no>1||~isempty(strfind(system.devices.info,'Arduino'))
        system.interface.indication=['   It seems like you are connecting more than one electronics or a single Arduino board to the PC, '];
        system.interface.length=strlength(system.interface.indication);
        system.interface.cutoff='   -';
        for i=1:ceil((system.interface.length-3)*system.interface.golden_ratio)
            system.interface.cutoff=strcat(system.interface.cutoff,' -');
        end
        system.interface.indication=['   It seems like you are connecting more than one electronics or a single Arduino board to the PC, ','\n',...
            '   please plug in *ONLY ONE* USB to UART Bridge first to finish the set up.'];
        fprintf([system.interface.cutoff,'\n',system.interface.indication,'\n',system.interface.cutoff,'\n']);
        clear i; clear MAC; clear temp; clear YourHeart;
        return;
    end
    clear i;
end

system.devices.info=UARTDevicesFunc();
[system.devices.no,~]=size(system.devices.info);
% In the last version, what's inside the bracket is (serialportlist("available")), it is sometimes not so accurate especailly for desktop computer.
if isempty(system.devices.info)
    fprintf(['   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n',...
        '   There are no devices connected to the PC currently, please make a double check.','\n',...
        '   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n']);
    clear MAC; clear temp; clear YourHeart;
    return;
else
    if isfield(system.devices,'arm') system.devices=rmfield(system.devices,'arm'); end
    if isfield(system.devices,'Arduino') system.devices=rmfield(system.devices,'Arduino'); end
    if isfield(system.devices,'state') system.devices=rmfield(system.devices,'state'); end
    if isfield(system,'human') system=rmfield(system,'human'); end
    if isfield(system,'arm') system=rmfield(system,'arm'); end
    if isfield(system,'states') system=rmfield(system,'states'); end
    if isfield(system,'date') system=rmfield(system,'date'); end
   
    % 2023.04.12
    % Instead of the complex algorithm to assign the port No. in
    % sequence when some of the arm IMUs are not connected with the PC,
    % we can forge a history documentation in the system struct to
    % store all the connection information for the same mac address.
    system.devices.history=[];
    for i=1:system.devices.no
        if contains(system.devices.info{i,1},system.devices.base.info.port)
            system.devices.history=[system.devices.history;strcat("Base: ",system.devices.info{i,1})];
        end
    end
    system.toggle=1; % This string is to stop the commnication without pulling out any devices. 1=on, 0=off.
    if ~isfield(temp.devices,'PC')||string(MAC)~=string(temp.devices.PC.mac)
        for i=1:system.devices.no
            if ~isempty(strfind(system.devices.info{i,1},'Arduino'))
                system.devices.Arduino.info.UART=system.devices.info{i,1};
                system.devices.Arduino.info.com=strfind(system.devices.Arduino.info.UART,'COM');
                % To change the single quotation marks on both sides of the char
                % to double quotation marks.
                system.devices.Arduino.info.port=string(system.devices.Arduino.info.UART(system.devices.Arduino.info.com:end-1));
                system.devices.Arduino.info.board=string(system.devices.Arduino.info.UART(9:system.devices.Arduino.info.com-3));
                system.devices.Arduino.info.board=replace(system.devices.Arduino.info.board,' ','');
                system.devices.history=[system.devices.history;strcat("Human: ",system.devices.info{i,1})];
            end
        end
        % The following line of code is to ensure the system will work properly
        % without connecting the Arduino board.
        if isfield(system.devices,'Arduino')
%             system.human.port=arduino(system.devices.Arduino.info.port,system.devices.Arduino.info.board);
            % 2023.04.11
            % The MATLAB and Arduino communication package could be more
            % advanced, but the function arduino() is only for directly
            % controlling the PIN on the board rather than realizing the
            % data reading and sending between the two based on the
            % information I have found so far, so in the future version, we
            % will use conventional serialport() function instead.

            system.human.port=serialport(system.devices.Arduino.info.port,115200);
            system.human.record=[];
        end
        system.devices.arm.info.com=[];
        system.devices.arm_no=0;
        for i=1:system.devices.no
            if isfield(system.devices,'Arduino')
                % 2023.04.09
                % Serious bug: we need to change all the
                % system.devices.info to string to make a comparison.
                if string(system.devices.info{i,2})~=system.devices.Arduino.info.port&&string(system.devices.info{i,2})~=system.devices.base.info.port
                    system.devices.arm.info.com=[system.devices.arm.info.com;string(system.devices.info{i,2})];
                end
            elseif string(system.devices.info{i,2})~=system.devices.base.info.port
                system.devices.arm.info.com=[system.devices.arm.info.com;string(system.devices.info{i,2})];
            end
        end
        if isfield(system.devices,'arm')
            for i=1:length(system.devices.arm.info.com)
                system.devices.arm_no=system.devices.arm_no+1;
                system.arm(i).port=serialport(system.devices.arm.info.com(i),115200);
                for j=1:length(system.devices.info)
                    if contains(system.devices.info{j,1},system.devices.arm.info.com(i))
                        system.devices.history=[system.devices.history;strcat(strcat(strcat("Arm(",num2str(i)),"): "),system.devices.info{j,1})];
                    end
                end
            end
        end
    
    elseif string(MAC)==string(temp.devices.PC.mac)
        if isfield(system,'base') system=rmfield(system,'base'); end
        % To detect if the base coordinate IMU was unplugged by mistake.
        system.devices.state.base_connection=0;
        for i=1:system.devices.no
            if contains(system.devices.info{i,2},temp.devices.base.info.port)
                system.devices.state.base_connection=1;
            end
        end
        if system.devices.state.base_connection~=1
            system.interface.indication=['The *BASE* is not plugged in right now, please check your connection and restart the experiment.'];
            system.interface.length=strlength(system.interface.indication);
            system.interface.cutoff='   -';
            for i=1:ceil((system.interface.length-3)*system.interface.golden_ratio)
                system.interface.cutoff=strcat(system.interface.cutoff,' -');
            end
            fprintf([system.interface.cutoff,'\n',system.interface.indication,'\n',system.interface.cutoff,'\n']);
            clearvars -except system;
            return;
        end
        system.devices.state.available_port={system.devices.info{:,2}}';
        system.devices.base.info.port=temp.devices.base.info.port;

        %% 2023.04.10 %%
        %% It seems like if we use the previous data, if the code has
        %% detected the record that the current devices have been connected
        %% with the PC according to the data sheet, we don't have to set up
        %% the serial link again.
        %%  - - - We have to delete the port first, then set up the link again.

        system.base.port=serialport(system.devices.base.info.port,115200);
        system.devices.history=temp.devices.history;

        % Delete the port number from the available list in
        % system.devices.state.available.port once a device has been set up
        % connection with the PC.
        for i=1:length(system.devices.state.available_port)
            if string(system.devices.state.available_port{i})==system.devices.base.info.port
                system.devices.state.available_port{i}={};
                % 2023.04.12
                % Originally the cellfun is called here to delete the empty
                % cell timely, but it will change the length of
                % available_port nearly for each loop, so we need to drag
                % the original line of code outside.
            end
        end
        system.devices.state.available_port(cellfun(@isempty,system.devices.state.available_port))=[];
        % To detect if there exists any connection information of the
        % Arduino board in the previous data sheet.
        for i=1:system.devices.no
            if ~isempty(strfind(system.devices.info{i,1},'Arduino'))
                for j=1:temp.devices.no
                    if ~isempty(strfind(temp.devices.info,'Arduino'))&&isfield(temp,'human')
                        system.devices.Arduino.info.port=temp.devices.Arduino.info.port;
                        system.devices.Arduino.info.board=temp.devices.Arduino.info.board;
                        system.human.port=serialport(temp.devices.Arduino.info.port,115200);
                        for k=1:length(system.devices.state.available_port)
                            if system.devices.state.available_port{k}==system.devices.Arduino.info.port
                                system.devices.state.available_port{k}={};
                            end
                        end
                        system.devices.state.available_port(cellfun(@isempty,system.devices.state.available_port))=[];
                    end
                end
            end
        end
        if ~isfield(temp,'human')
            for i=1:system.devices.no
                if ~isempty(strfind(system.devices.info{i,1},'Arduino'))
                    system.devices.Arduino.info.UART=system.devices.info{i,1};
                    system.devices.Arduino.info.com=strfind(system.devices.Arduino.info.UART,'COM');
                    system.devices.Arduino.info.port=string(system.devices.Arduino.info.UART(system.devices.Arduino.info.com:end-1));
                    system.devices.Arduino.info.board=string(system.devices.Arduino.info.UART(9:system.devices.Arduino.info.com-3));
                    system.devices.Arduino.info.board=replace(system.devices.Arduino.info.board,' ','');
                end
            end
        end
        if isfield(system.devices,'Arduino')
            system.human.port=serialport(system.devices.Arduino.info.port,115200);
            for i=1:length(system.devices.state.available_port)
                if system.devices.state.available_port{i}==system.devices.Arduino.info.port
                    system.devices.state.available_port{i}={};
                end
            end
            system.devices.state.available_port(cellfun(@isempty,system.devices.state.available_port))=[];
        end
        % 2023.04.13
        % The bug that Arduino information will be written in the history
        % record again and again even though it exists has been solved.
        old_Arduino=0; % Currently there are no variables stored in the system struct can be used.
        for i=1:length(system.devices.history)
            if contains(system.devices.history,'Arduino')
                old_Arduino=old_Arduino+1;
            end
        end
        if old_Arduino~=0
            for i=1:length(system.devices.info)
                if contains(system.devices.info{i,1},'Arduino')
                    system.devices.history=[system.devices.history;strcat("Human: ",system.devices.info{i,1})];
                end
            end
        end
        clear old_Arduino;

        system.devices.arm_no=0;
        for i=1:system.devices.no
            if isempty(strfind(system.devices.info{i,1},...
                    strcat("Silicon Labs CP210x USB to UART Bridge (",system.devices.base.info.port,")")))&&...
                    ~contains(system.devices.info{i,1},'Arduino')
                system.devices.arm_no=system.devices.arm_no+1;
            end
        end

        if system.devices.arm_no~=0
            % 2023.04.09
            % The code will first detect which IMU serial ports connected right now are
            % exactly the same as defined in the previous data sheet, then for the rest
            % new ones, they will be assigned into the vacancies.
            % e.g.
            % No. 1: If the IMUs connected to the PC previously were
            % labelled as 2 and 3, but right now we are going to connect
            % 1, 2 and 3, then the newly 1 will be assigned into the
            % vacancy previously.
            % No. 2: Previous: 2,3          Now: 2, 3, 4
            % Because the system doesn't know it's arm 4, so arm 4 will be
            % assigned into position 1, it is a limitation of my code right
            % now, so please make sure you connect all the devices
            % correctly at the begining, and do not change too much about
            % the set up.

            if length(temp.devices.history)~=0
                for i=1:length(temp.devices.history)
                    for j=1:system.devices.arm_no
                        if contains(temp.devices.history{i},system.devices.state.available_port{j})
                            arm_info=temp.devices.history{i};
                            arm_ord=str2num(arm_info(5));
                            system.arm(arm_ord).port=serialport(string(system.devices.state.available_port{j}),115200);
                            system.devices.arm.info.com{arm_ord}=system.devices.state.available_port{j};
                            system.devices.state.available_port{j}={};
                        end
                    end
                end
                system.devices.state.available_port(cellfun(@isempty,system.devices.state.available_port))=[];
                clear arm_info; clear arm_ord;
                if length(system.devices.state.available_port)~=0
                    UART_no=0;
                    for i=1:length(temp.devices.history)
                        if contains(temp.devices.history{i},'UART')
                            UART_no=UART_no+1;
                        end
                    end
                    for i=1:length(system.devices.state.available_port)
                        system.arm(UART_no+i-1).port=serialport(string(system.devices.state.available_port{i}),115200);
                        system.devices.arm.info.com{UART_no+i-1}=system.devices.state.available_port{i};
                        system.devices.history=[system.devices.history;...
                            strcat(strcat(strcat(strcat("Arm(",num2str(UART_no+i-1)),"): Silicon Labs CP210x USB to UART Bridge ("),...
                            string(system.devices.state.available_port{i})),")")];
                    end
                    clear UART_no;
                end
            else
                system.devices.arm.info.com=[];
                system.devices.history=temp.devices.history;
                for i=1:length(system.devices.state.available_port)
                    system.arm(i).port=serialport(string(system.devices.state.available_port{i}),115200);
                    system.devices.arm.info.com{i}=[system.devices.arm.info.com;string(system.devices.state.available_port{i})];
                    for j=1:system.devices.no
                        if contains(system.devices.info{j,1},system.devices.state.available_port{i})
                            system.devices.history=[system.devices.history;strcat(strcat(strcat("Arm(",num2str(i)),"): "),string(system.devices.info{j,1}))];
                        end
                    end
                end
            end
        end
    end
    clear MAC; clear temp;
    
    % The inputbuffersize and outputbuffersize settings cannot work
    % properly for MATLAB version R2021b and the former ones, we need
    % to add an if sentence here, and to convert the code into C/C++ in
    % the future, we don't have to consider so much about it.
    if isfield(system,'arm')
        for i=1:length(system.devices.arm_no)
            if system.devices.PC.ram>16&&contains(system.devices.arm.info.com(i),'COM')
                set(system.arm(i).port,'inputBufferSize',1024000);
                set(system.arm(i).port,'outputBufferSize',1024000);
            end
            system.arm(i).record=[];
        end
    end
    if system.devices.PC.ram>16
        set(system.base.port,'inputBufferSize',1024000);
        set(system.base.port,'outputBufferSize',1024000);
    end
    if isfield(system,'human')
        system.human.record=[];
        system.states.instant=[];
    end
end



%%      Data Collection and Communication Section      %%

% Temporarily to make sure the return value will not be over written by
% that with exactly the same name of variable, we need to set up different functions.

if isfield(system,'base')
    % To make sure the callback data of the base IMU is not empty, the function
    % of base should be executed firstly.
    addpath('.\DataProc'); addpath('.\Filter');
    configureCallback(system.base.port,"terminator",@readSerialData_b);
    if isfield(system,'arm')
        % 2023.04.12
        % The following lines of codes are only applicable for the case
        % that there are only two IMUs mounted on the end effectors of the
        % SRAs, in the future, there could be four, we need to think about
        % a smarter way to ensure all the *CONNECTED* ones will work
        % properly.
        try
            configureCallback(system.arm(1).port,"terminator",@readSerialData_a1);
        catch
            configureCallback(system.arm(2).port,"terminator",@readSerialData_a2);
        end
        if length(system.devices.arm_no)==2
            try
                configureCallback(system.arm(2).port,"terminator",@readSerialData_a2);
            catch
                configureCallback(system.arm(1).port,"terminator",@readSerialData_a1);
            end
        end
    end
    if isfield(system,'human')
        configureCallback(system.human.port,"terminator",@readSerialData_h);
        % 2023.04.13
        % Realize the data sending from MATLAB to Arduino as well.
%         fprintf(['wdnmd','\n']);

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
            % 2023.04.13
            % Serious issue has been found that the communication between
            % MATLAB and Arduino cannot be terminated by the system.toggle,
            % so we temporarily need to add another lines of codes to shut
            % down it forcedly.
            % Most likely, the configureCallback function for Arduino is
            % not triggered ever before.
            
            if isfield(system,'human')
                configureCallback(system.human.port,"off");
                flush(system.human.port);
                delete(system.human.port);
            end

            fprintf(['   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n',...
                '   The serial port communication is ended.','\n',...
                '   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -','\n']);
            break;
        end
    end
end

% 2023.04.11
% Fix the bug that when base and Arduino board were connected to the PC for
% the first time, the PC information will be stored.
if isfield(system,'base')&&system.devices.no>=2
    system.date=datestr(now);
    system.date=replace(system.date,'-','_');
    system.date=replace(system.date,':','_');
    system.date=replace(system.date,' ','_');
    states=[];
    if isfield(system,'human')
        system.states.human=[];
        states=[states system.states.human];
    end
    if isfield(system,'arm')
        system.states.arm=[];
        for i=1:length(system.devices.arm_no)
            system.states.arm=[system.states.arm system.arm(i).record];
        end
        states=[states system.states.arm];
    end
%     if isfield(system,'human')||isfield(system,'arm')
%          save(['Results/','states_',system.date,'.txt'],'states','-ascii');
%     end
    save(['Results/','system_',system.date,'.mat'],'system');

    
    
    %%      Plot Section      %%
    if isfield(system,'arm')
        for i=1:length(system.devices.arm_no)
            system.arm(i).step=length(system.arm(i).record);
            for j=1:system.arm(i).step
                system.arm(i).t(j)=1/system.Hz*j;
            end
            figure(i);
            subplot(1,2,1);
            if length(system.mode)==length('authentic')
                plot(system.arm(i).t,system.arm(i).record(:,1),'r','linewidth',1);
                hold on; axis on; grid on;
                plot(system.arm(i).t,system.arm(i).record(:,2),'b','linewidth',1);
                xlabel('Time (s)'); ylabel('Angle (rad)'); legend('\theta','\phi');
                subplot(1,2,2);
                plot(system.arm(i).t,system.arm(i).record(:,3),'r','linewidth',1);
                hold on; axis on; grid on;
                plot(system.arm(i).t,system.arm(i).record(:,4),'b','linewidth',1);
                xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)'); legend({'$\dot{\theta}$','$\dot{\phi}$'},'interpreter','latex');
            elseif length(system.mode)==length('perfect')
                if round(system.arm(i).step/system.Hz)>10 % Stablization time
                    plot(system.arm(i).t(10*system.Hz:end)-10,system.arm(i).record(10*system.Hz:end,1),...
                        'r','linewidth',1);
                    hold on; axis on; grid on;
                    plot(system.arm(i).t(10*system.Hz:end)-10,system.arm(i).record((10*system.Hz:end),2),...
                        'b','linewidth',1);
                    xlabel('Time (s)'); ylabel('Angle (rad)'); legend('\theta','\phi');
                    subplot(1,2,2);
                    plot(system.arm(i).t(10*system.Hz:end)-10,system.arm(i).record((10*system.Hz:end),3),...
                        'r','linewidth',1);
                    hold on; axis on; grid on;
                    plot(system.arm(i).t(10*system.Hz:end)-10,system.arm(i).record((10*system.Hz:end),4),...
                        'b','linewidth',1);
                    xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)'); legend({'$\dot{\theta}$','$\dot{\phi}$'},'interpreter','latex');
                else
                    plot(system.arm(i).t,system.arm(i).record(:,1),'r','linewidth',1);
                    hold on; axis on; grid on;
                    plot(system.arm(i).t,system.arm(i).record(:,2),'b','linewidth',1);
                    xlabel('Time (s)'); ylabel('Angle (rad)'); legend('\theta','\phi');
                    subplot(1,2,2);
                    plot(system.arm(i).t,system.arm(i).record(:,3),'r','linewidth',1);
                    hold on; axis on; grid on;
                    plot(system.arm(i).t,system.arm(i).record(:,4),'b','linewidth',1);
                    xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)'); legend({'$\dot{\theta}$','$\dot{\phi}$'},'interpreter','latex');
                end
            end
            % Add a super title to the subplot
            % The function suptitle was eliminated from version 2018, now we
            % need to use sgtitle (subplot grid title) instead.
            sgtitle(['Arm ',num2str(i)]);
            set(gcf,'position',[50,250,1000,400]);
        end
    end
end
clear i; clear j; clear states;
clear YourHeart;


