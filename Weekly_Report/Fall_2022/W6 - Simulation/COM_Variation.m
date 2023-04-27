clear all; clc;
syms l theta;
delta_l=l/theta*(2/theta*sin(theta/2)-cos(theta/2));
for i=1:10
    theta_fig1(i)=pi/2-(i-1)*((pi/2-pi/6)/10);
    delta_l_fig1(i)=double(subs(delta_l,[theta,l],[theta_fig1(i),1]));
end
figure(1);
subplot(1,2,1);
plot(theta_fig1/pi*180,delta_l_fig1,'linewidth',1);
grid on; axis on;
xlabel('Bending Angle θ (°)');
ylabel('Distance between COM & chord center ΔL (m)');
title('Relationship between ΔL and θ when L=1 m');
subplot(1,2,2);
for i=1:10
    theta_fig1(i)=pi/2-(i-1)*((pi/2-pi/6)/10);
    delta_l_fig1(i)=double(subs(delta_l,[theta,l],[theta_fig1(i),0.3]));
end
plot(theta_fig1/pi*180,delta_l_fig1,'linewidth',1);
grid on; axis on;
xlabel('Bending Angle θ (°)');
ylabel('Distance between COM & chord center ΔL (m)');
title('Relationship between ΔL and θ when L=0.3 m');
set(gcf,'position',[0,0,950,320]);

figure(2);
for i=1:10
    l_fig2(i)=1-0.1*(i-1);
    delta_l_fig2(i)=double(subs(delta_l,[theta,l],[pi/2,l_fig2(i)]));
end
plot(l_fig2,delta_l_fig2,'linewidth',1);
grid on; axis on;
xlabel('Length of SRA segment L (m)');
ylabel('Distance between COM & chord center ΔL (m)');
title('Relationship between ΔL and L when θ=90°');
set(gcf,'position',[700,300,700.1,400]);