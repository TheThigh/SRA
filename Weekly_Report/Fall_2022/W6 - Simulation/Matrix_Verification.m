clear all; clc;
syms theta L;
format short;
% The rotation matrix
R=[cos(theta) sin(theta) 0 2*L*(sin(theta/2)^2)/theta;
    -sin(theta) cos(theta) 0 L*sin(theta)/theta;
    0 0 1 0;
    0 0 0 1];
R_base=[cos(-pi/2) -sin(-pi/2) 0 -5;
    sin(-pi/2) cos(-pi/2) 0 10;
    0 0 1 0;
    0 0 0 1];
R1=subs(R,[theta,L],[pi/3,3]);
R2=subs(R,[theta,L],[pi/3,3]);
Joint=double(R_base*R1);
End_effector=double(R_base*R1*R2);