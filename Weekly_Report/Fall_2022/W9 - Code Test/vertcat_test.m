clear all; clc;
theta=sym('theta',[1,2]);
R=struct('theta',zeros(2,2));
R.theta=[1 1; 2 2]
k=[theta(1)^2 theta(1)+7*theta(2);
    theta(1)*6-7 theta(1)*theta(2)];
p=[1 2];
fig=(subs(k,theta,p))
intm=simplify(k*k)
sym2poly(intm)