% This subscript is just to compare the results of exact solution and
% solution using Euler's Method with different step size h, and to learn
% about the characteristic of the stiff system.
% 2022.10.26

clear all; clc;
% func=input(['Please enter your ODE.','\n']);
% % The basic format of this input should be as follows,
% % @(t,y) -20*y+7*exp(-0.5*t), and the left hand side of the equation is
% % dy/dt.
% t0=input(['Please enter the initial value of independent variable','\n']);
% y0=input(['Please enter the initial value of the dependent variable','\n']);
% h=input(['Please enter the step size','\n']);
% tn=input(['Please enter the point at which you would like to evalute the solution','\n']);

%% Test Code %%
% 2022.10.26
func=@(t,y) -1000*y;
t0=0; y0=1;
h(1)=0.00001;
h(2)=0.0005;
h(3)=0.0001;
tn=1;
%% End %%
% subplot(1,2,1);
figure(1);
t(1)=t0; y(1)=y0;
for j=1:3
    n(j)=(tn-t0)/h(j);
    for i=1:n(j)
        y(i+1)=y(i)+h(j)*func(t(i),y(i));
        t(i+1)=t0+i*h(j);
    end
    plot(t,y,'color',[(255/3*j)/255,(255-255/3*j)/255,(255/8*j)/255]);
    hold on; grid on;
end
xlabel('t'); ylabel('y');
title('Numerical solution using Eulers Method with different step size');
xlim([0,0.006]);
n_max=100000;
for i=1:n_max
    if i==1
        t_standard(i)=t0;
    else
        t_standard(i)=t0+(i-1)*tn/n_max;
    end
    y_standard(i)=exp(-1000*t_standard(i));
end
plot(t_standard,y_standard,'b');
legend(['h=',num2str(h(1))],['h=',num2str(h(2))],['h=',num2str(h(3))],'Exact Solution');

% The precison of ezplot is so low.
% subplot(1,2,2);
% ezplot('exp(-1000*t)',[0,tn]);
% title('The exact solution of y=e^(-1000t)');
% xlabel('t'); ylabel('y');
% grid on;
% xlim([0,1]);
% set(gcf,'position',[50,50,1300,450]);

figure(2);
h1=0.1;
t1(1)=t0; y1(1)=y0;
n2=(tn-t0)/h1;
for i=1:n2
        y1(i+1)=y1(i)+h1*func(t1(i),y1(i));
        t1(i+1)=t0+i*h1;
end
plot(t1,y1,'color',[(255/3*1)/255,(255-255/3*1)/255,(255/8*1)/255],'linewidth',1);
hold on; grid on;
xlabel('t'); ylabel('y');
legend('h=0.1');
title('The numerical solution of  y=e^(-1000t) with a large step size');