function readSerialData_h(eu_ang,~)

global system;
if system.toggle==0
    configureCallback(system.human.port,"off");
    flush(system.human.port);
    delete(system.human.port);
else
    if system.controller==0
        
        % 2023.06.05
        % Sometimes though the communication between PC and Arduino has
        % been succuessfully set up, the data transmitting is not so
        % promising, and it's unlikely for us to monitor the command
        % window all the time to identify if the human data has been
        % sent to MATLAB because the streaming data will overwrite the
        % indication interface for the users.
        % So our solution is to leave 20s for the procedure to
        % response, if the record data for human is still empty, there
        % will be a WARNING pop-up in the command window, but not
        % terminate the procedure.
        % 2023.06.06
        % Temporarily the following lines of code do not work due to some
        % reasons, even in the readSerialData_a1 function.
        
        if isempty(system.human.record)
            if system.human.temp.ti~=-1
                system.human.temp.ti=toc(system.human.temp.t0);
                if system.human.temp.ti>20
                    addpath('.\Funcs');
                    cprintf('*err',['   ! ! ! WARNING: Human data has not been recorded ! ! !','\n']);
                    system.human.temp.ti=-1;
                end
            end
        end

        data=readline(eu_ang);
        % The incoming data is string, it should be transformed into char
        % aray first to finish the subsequent operations.
        data=char(data);
        if ~isempty(str2num(data(1)))
            l_hchar=length(data);
            space_loc=[];
            for i=1:l_hchar
                if isempty(str2num(data(i)))&&data(i)~='.'&&data(i)~='-'&&data(i)~='n'&&data(i)~='a'
                    space_loc=[space_loc;i];
                end
            end
            system.human.temp.time=str2num(data(1:space_loc(1)-1));
            system.human.temp.yaw=str2num(data(space_loc(1)+1:space_loc(2)-1));
            system.human.temp.pitch=str2num(data(space_loc(2)+1:space_loc(3)-1));
            % To cope with the issue that some terms are "nan" rather than
            % a specific number for roll angle.
            if data(space_loc(3)+1:end)=="nan"
                if isempty(system.human.record)
                    system.human.temp.roll=0;
                else
                    system.human.temp.roll=system.human.record(end,end);
                end
            else
                system.human.temp.roll=str2num(data(space_loc(3)+1:end));
            end
            
            % The first step is to change the range of roll
            % angle from [-2*pi, 2*pi] to [-pi, pi]. Even
            % though we have done similar treatment in Arduino,
            % it is still not so promising.
            while abs(system.human.temp.roll)>2*pi
                if system.human.temp.roll>0
                    system.human.temp.roll=system.human.temp.roll-2*pi;
                elseif system.human.temp.roll<0
                    system.human.temp.roll=system.human.temp.roll+2*pi;
                end
            end
            while abs(system.human.temp.roll)>pi
                if system.human.temp.roll>0
                    system.human.temp.roll=system.human.temp.roll-2*pi;
                elseif system.human.temp.roll<0
                    system.human.temp.roll=system.human.temp.roll+2*pi;
                end
            end

            % 2023.06.05
            % There is another issue with the time that at some of the
            % points, there exist repeated time instants which will account
            % for extra storage space and it is not our expectation, we
            % shall update the record datasheet with the former one, otherwise there will be some errors for angular velocity calculations.

            if ~isempty(system.human.record)
                if system.human.temp.time==system.human.record(end,1)
                    system.human.record=system.human.record;
                else
                                      
                    % Angular velocities
                    system.human.temp.dyaw=(system.human.temp.yaw-system.human.record(end,2))...
                        /(system.human.temp.time-system.human.record(end,1));
                    system.human.temp.dpitch=(system.human.temp.pitch-system.human.record(end,3))...
                        /(system.human.temp.time-system.human.record(end,1));
                    system.human.temp.droll=(system.human.temp.roll-system.human.record(end,4))...
                        /(system.human.temp.time-system.human.record(end,1));

                    % Angular accelerations
                    system.human.temp.ddyaw=(system.human.temp.dyaw-system.human.record(end,5))...
                        /(system.human.temp.time-system.human.record(end,1));
                    system.human.temp.ddpitch=(system.human.temp.dpitch-system.human.record(end,6))...
                        /(system.human.temp.time-system.human.record(end,1));
                    system.human.temp.ddroll=(system.human.temp.droll-system.human.record(end,7))...
                        /(system.human.temp.time-system.human.record(end,1));

                    % 2023.06.07
                    % The following lines of code will make all the filters
                    % ineffective, which is a serious issue. However, they
                    % cannot be deleted because without them there will be
                    % some issues with "authentic" mode.
                    %  - Fixed...
                    system.human.record=[system.human.record;system.human.temp.time ...
                    system.human.temp.yaw system.human.temp.pitch system.human.temp.roll ...
                    system.human.temp.dyaw system.human.temp.dpitch system.human.temp.droll ...
                    system.human.temp.ddyaw system.human.temp.ddpitch system.human.temp.ddroll];
                end

            else
                system.human.temp.dyaw=0;
                system.human.temp.dpitch=0;
                system.human.temp.droll=0;
                system.human.temp.ddyaw=0; system.human.temp.ddpitch=0; system.human.temp.ddroll=0;
                system.human.record=[system.human.record;system.human.temp.time ...
                    system.human.temp.yaw system.human.temp.pitch system.human.temp.roll ...
                    system.human.temp.dyaw system.human.temp.dpitch system.human.temp.droll ...
                    system.human.temp.ddyaw system.human.temp.ddpitch system.human.temp.ddroll];
            end


            %% Filter Design %%
            
            if length(system.mode)==length('perfect')&&system.human.temp.time>10
                
                % Filter design for the 3 angles.
                system.human.temp.yaw=doFilter_human_py(system.human.record(:,2));
                system.human.temp.yaw=system.human.temp.yaw(end);
                system.human.temp.pitch=doFilter_human_py(system.human.record(:,3));
                system.human.temp.pitch=system.human.temp.pitch(end);
                system.human.temp.roll=doFilter_human_roll(system.human.record(:,4));
                system.human.temp.roll=system.human.temp.roll(end);
                
                % 2023.06.06
                % The noise for the velocities of yaw and pitch
                % angles are similar, we can use the same filter
                % for a trial.
                
                system.human.temp.dyaw=doFilter_human_dyaw(system.human.record(:,5));
                system.human.temp.dyaw=system.human.temp.yaw(end);
                system.human.temp.dpitch=doFilter_human_dpitch(system.human.record(:,6));
                system.human.temp.dpitch=system.human.temp.dpitch(end);

                
                % 2023.06.06
                % Since the roll angle is not so important in the
                % control of the system, the angular velocity can be
                % computed based on the filtered roll angles
                % temporarily.
                
                system.human.temp.droll=doFilter_human_droll([system.human.record(:,7)]);
                system.human.temp.droll=system.human.temp.droll(end);

                % Optimization for the angular accelerations: since if we
                % insist on adding a filter to the original data of angular
                % accelerations, the error will be even larger, in the
                % "perfect" mode, they should be computed based on the
                % filtered velocities.
                % 2023.06.07
                % Using the method mentioned above will only make the
                % efficiency of the procedure even worse, so we have no
                % choice but to use the orginal data.
                
%                 system.human.temp.ddyaw=(system.human.temp.dyaw-system.human.record(end,5))...
%                     /(system.human.temp.time-system.human.record(end,1));
%                 system.human.temp.ddpitch=(system.human.temp.dpitch-system.human.record(end,6))...
%                     /(system.human.temp.time-system.human.record(end,1));
%                 system.human.temp.ddroll=(system.human.temp.droll-system.human.record(end,7))...
%                     /(system.human.temp.time-system.human.record(end,1));

                system.human.temp.ddyaw=doFilter_human_ddyaw(system.human.record(:,8));
                system.human.temp.ddyaw=system.human.temp.ddyaw(end);
                system.human.temp.ddpitch=doFilter_human_ddpitch(system.human.record(:,9));
                system.human.temp.ddpitch=system.human.temp.ddpitch(end);
                system.human.temp.ddroll=doFilter_human_ddroll(system.human.record(:,10));
                system.human.temp.ddroll=system.human.temp.ddroll(end);
                
                system.human.record(end,:)=[system.human.temp.time ...
                    system.human.temp.yaw system.human.temp.pitch system.human.temp.roll ...
                    system.human.temp.dyaw system.human.temp.dpitch system.human.temp.droll ...
                    system.human.temp.ddyaw system.human.temp.ddpitch system.human.temp.ddroll];
            end

%             display([system.human.temp.time ...
%                 system.human.temp.yaw system.human.temp.pitch system.human.temp.roll]);

%             display(system.human.record(end,:));



            % 2023.06.07
            %% %%%%%% Controller Design %%%%%% %%
            % The force or torque generated by the arm should be computed
            % by the state variables of both arm and human in this section,
            % than it can be converted into pressure supply in Arduino
            % board.

            

        end
    end

end

end


