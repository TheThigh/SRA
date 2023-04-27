clear all; clc;
func=@(t,y) -0.001*y;
t0=0; y0=1;
h(1)=1;
h(2)=0.01;
h(3)=0.005;
tn=6000;
t(1)=t0; y(1)=y0;
figure(1);
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
xlim([0,6000]);
n_max=1000;
for i=1:n_max
    if i==1
        t_standard(i)=t0;
    else
        t_standard(i)=t0+(i-1)*tn/n_max;
    end
    y_standard(i)=exp(-0.001*t_standard(i));
end
plot(t_standard,y_standard,'b');
legend(['h=',num2str(h(1))],['h=',num2str(h(2))],['h=',num2str(h(3))],'Exact Solution');

% It will take about 3 mins for the following code, you can comment them.
figure(2);
h1=0.00001;
t1(1)=t0; y1(1)=y0;
n2=(tn-t0)/h1;
for i=1:n2
        y1(i+1)=y1(i)+h1*func(t1(i),y1(i));
        t1(i+1)=t0+i*h1;
end
plot(t1,y1,'color',[(255/3*1)/255,(255-255/3*1)/255,(255/8*1)/255],'linewidth',1);
hold on; grid on;
xlabel('t'); ylabel('y');
legend(['h=',num2str(h1)]);
title('The numerical solution of  y=e^(-0.001t) with a smaller step size');