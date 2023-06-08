function data_plot(data,part)

% For the compactness of code, from Jun 5 2023, we are going to use
% functions instead of code in the main function for repeated used
% sentences.

global system;
[r,c]=size(data);
if part=="human"
    if length(system.mode)==length('authentic')
        figure;
        % Plot the yaw, pitch angles.
        subplot(2,3,1);
        plot(data(:,1),data(:,2),'linewidth',1);
        hold on; grid on; axis on;
        plot(data(:,1),data(:,3),'linewidth',1);
        xlabel('Time (s)'); ylabel('Angle (rad)'); legend('Yaw: \alpha','Pitch: \beta','Roll: \gamma');
        % Plot the yaw, pitch angular velocities.
        subplot(2,3,2);
        plot(data(:,1),data(:,5),'linewidth',1);
        hold on; grid on; axis on;
        plot(data(:,1),data(:,6),'linewidth',1);
        xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
        legend({'$Yaw: \dot{\alpha}$','$Pitch: \dot{\beta}$','$Roll: \dot{\gamma}$'},'interpreter','latex');
        % Plot the yaw, pitch angular accelerations.
        subplot(2,3,3);
        plot(data(:,1),data(:,8),'linewidth',1);
        hold on; grid on; axis on;
        plot(data(:,1),data(:,9),'linewidth',1);
        xlabel('Time (s)'); ylabel('Angular Acceleration (rad/s^2)');
        legend({'$Yaw: \ddot{\alpha}$','$Pitch: \ddot{\beta}$','$Roll: \ddot{\gamma}$'},'interpreter','latex');

        % Plot the information of roll angle
        subplot(2,3,4);
        plot(data(:,1),data(:,4),'linewidth',1);
        grid on; axis on;
        xlabel('Time (s)'); ylabel('Angle (rad)'); legend('Roll: \gamma');
        subplot(2,3,5);
        plot(data(:,1),data(:,7),'linewidth',1);
        grid on; axis on;
        xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
        legend({'$Roll: \dot{\gamma}$'},'interpreter','latex');
        subplot(2,3,6);
        plot(data(:,1),data(:,10),'linewidth',1);
        grid on; axis on;
        xlabel('Time (s)'); ylabel('Angular Acceleration (rad/s^2)');
        legend({'$Roll: \ddot{\gamma}$'},'interpreter','latex');

    elseif length(system.mode)==length('perfect')
        figure(2);
        perfect_loc=1;
        temp_loc=1;
        for i=1:r
            if data(i,1)>=10&&temp_loc~=0
                temp_loc=i;
                perfect_loc=temp_loc;
                temp_loc=0;
            end
            % "return" cannot be added here because it will jump out the
            % very big loop directly without plotting any figures.
        end

        subplot(2,3,1);
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,2),'linewidth',1);
        hold on; axis on; grid on;
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,3),'linewidth',1);
        xlabel('Time (s)'); ylabel(' Angle (rad)'); legend('Yaw: \alpha','Pitch: \beta','Roll: \gamma');
        subplot(2,3,2);
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,5),'linewidth',1);
        hold on; axis on; grid on;
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,6),'linewidth',1);
        xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
        legend({'$Yaw: \dot{\alpha}$','$Pitch: \dot{\beta}$','$Roll: \dot{\gamma}$'},'interpreter','latex');
        subplot(2,3,3);
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,8),'linewidth',1);
        hold on; grid on; axis on;
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,9),'linewidth',1);
        xlabel('Time (s)'); ylabel('Angular Acceleration (rad/s^2)');
        legend({'$Yaw: \ddot{\alpha}$','$Pitch: \ddot{\beta}$','$Roll: \ddot{\gamma}$'},'interpreter','latex');

        subplot(2,3,4);
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,4),'linewidth',1);
        grid on; axis on;
        xlabel('Time (s)'); ylabel('Angle (rad)'); legend('Roll: \gamma');
        subplot(2,3,5);
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,7),'linewidth',1);
        grid on; axis on;
        xlabel('Time (s)'); ylabel('Angular Velocity (rad/s)');
        legend({'$Roll: \dot{\gamma}$'},'interpreter','latex');
        subplot(2,3,6);
        plot(data(perfect_loc:end,1)-10,data(perfect_loc:end,10),'linewidth',1);
        grid on; axis on;
        xlabel('Time (s)'); ylabel('Angular Acceleration (rad/s^2)');
        legend({'$Roll: \ddot{\gamma}$'},'interpreter','latex');

    end

    sgtitle('Human Data');
    set(gcf,'position',[20,50,1450,750]);

end

end


