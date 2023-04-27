% This version is used to solve the problem of symbolic variable array
% differentiation.
clear all; clc;
format short;

% Fixed position in inertia frame
pfx=-1;
pfy=1;

% The number of link for each side of the SRA.
n_link=2;

%% SRA Parameters %%
% Segment stiffness
k=[2.5,2];
% Segment damping coefficient
b=[1,0.9];
% Segment length & mass
L=[0.3,0.3];
m=[1.25,1.25];

g=9.81;
%% End %%

theta=sym('theta',[1,n_link]);
R=struct('theta',zeros(4,4));
for i=1:n_link
    % The expression of the standand derived transformation/rotation
    % matrix.
    R(i)=struct('theta',zeros(4,4));
    R(i).theta=[cos(theta(i)) sin(theta(i)) 0 2*L(i)*(sin(theta(i)/2)^2)/theta(i);
    -1*sin(theta(i)) cos(theta(i)) 0 L(i)*sin(theta(i))/theta(i);
    0 0 1 0;
    0 0 0 1];
end

% Calculate the intermediate rotation matrix.
R_intm=struct('theta',zeros(4,4));
for j=1:n_link
    if j==1
        R_intm(j).theta=R(1).theta;
    else
        R_intm(j).theta=R_intm(j-1).theta*R(j).theta;
    end
end

% Twist matrix in 2D problem
% As the SRA was initally horizontally fixed on the wall, it will bounce up
% and down, however, its direction cannot be justified by the theta value
% of SRA, we have to set up an individual transformation matrix rotating around z axis for it.

% 1. Bounce down                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
Rz_down=[cos(-pi/2) -sin(-pi/2) 0 pfx;
    sin(-pi/2) cos(-pi/2) 0 pfy;
    0 0 1 0;
    0 0 0 1];

% Calculate the energy for each part
% Potential energy due to gravity (the zero potential surface is the vertical position fixed)
p_x=struct('theta',zeros(1,1)); p_y=struct('theta',zeros(1,1));
delta_p_x=struct('theta',zeros(1,1)); delta_p_y=struct('theta',zeros(1,1));
potential_g_y=struct('theta',[]);
R_pos=struct('theta',zeros(4,4));
for i=1:n_link
    R_pos(i).theta=Rz_down*R_intm(i).theta;
    p_x(i).theta=R_pos(i).theta(1,4);
    p_y(i).theta=R_pos(i).theta(2,4);
end
delta_p_y(1).theta=p_x(1).theta-pfx;
delta_p_x(1).theta=p_y(1).theta-pfy;
for i=2:n_link
    delta_p_y(i).theta=p_x(i).theta-p_x(i-1).theta;
    delta_p_x(i).theta=p_y(i).theta-p_y(i-1).theta;
end
% Calculate the absolute distance between the original inertia frame and
% the COM of each link.
potential_g_y(1).theta=delta_p_y(1).theta/2;
for i=2:n_link
    potential_g_y(i).theta=p_y(i-1).theta+delta_p_y(i).theta/2;
end

% Calculate the manipulator Jacobian matrix
o=struct('theta',zeros(3,1)); z=struct('theta',zeros(3,1));
o(1).theta=[pfx;pfy;0];
z(1).theta=[0;0;1];
for i=1:n_link
    o(i+1).theta=[p_x(1).theta;p_y(1).theta;0];
    z(i+1).theta=[R_pos(i).theta(1,3);R_pos(i).theta(2,3);R_pos(i).theta(3,3)];
end
J_v=struct('theta',zeros(3,1)); J_w=struct('theta',zeros(3,1));
for i=1:n_link
    J_v(i).theta=cross(z(i).theta,o(end).theta-o(i).theta);
    J_w(i).theta=z(i).theta;
end

% Kinetic Energy Calculation

% Potential Energy Calculation, which is based on the Lagrange's Equation.
% We don't have to work out the part due to stiffness and damping as they
% are about theta and theta dot respectively.
P_g_real=0;
P_g=struct('theta',zeros(1,1));
for i=1:n_link
    P_g_real=P_g_real+m(i)*g*potential_g_y(i).theta;
end
for i=1:n_link
    P_g(i).theta=diff(P_g_real,theta(i));
end

% Intertia Matrix
J_linear=struct('theta',zeros(2,n_link));
M_linear=struct('theta',zeros(n_link,n_link));
M_angular=struct('theta',zeros(n_link,n_link));
M_total=struct('theta',zeros(n_link,n_link));
I=zeros(n_link,1);
for i=1:n_link
    J_linear(i).theta=jacobian([R_pos(i).theta(1,4),R_pos(i).theta(2,4)],theta);
    M_linear(i).theta=m(i)*transpose(J_linear(i).theta)*J_linear(i).theta;
    I(i)=1/12*m(i)*(L(i))^2;
    J_angular=zeros(1,n_link);
    J_angular(1:i)=1;
    M_angular(i).theta=I(i)*1/2*transpose(J_angular)*1/2*J_angular;
    M_total(i).theta=M_linear(i).theta+M_angular(i).theta; 
end
M=M_total(1).theta;
for i=2:n_link
    M=M+M_total(i).theta;
end

% Centripetal-Coriolis Matrix

theta_dot=sym('theta_dot',[1,n_link]);
sum_element=0;
sum_intm=struct('theta',zeros(1,1));
C_element=cell([n_link,n_link]);
for i=1:n_link
    for j=1:n_link
        C_element{i,j}=0;
    end
end
for i=1:n_link
    for j=1:n_link
        for k=1:n_link
            sum_intm(k).theta=1/2*(diff(M(i,j),theta(k))+diff(M(i,k),theta(j))-diff(M(k,j),theta(i)))*theta_dot(k);
            sum_element=sum_element+sum_intm(k).theta;
        end
        C_element{i,j}=sum_element; 
    end
end



%% Test Data File %%
q=[pi/6 pi/6];
dq=[4 8];
ddqi=[0 0];
tau_in=[0 0.03];
M=double(subs(M,theta,q));
% C_element.theta=double(subs(C_element.theta,[theta,theta_dot],[q,dq]));
% R.theta=double(subs(R.theta,theta,q)); R_intm.theta=double(subs(R_intm.theta,theta,q)); R_pos.theta=double(subs(R_pos.theta,theta,q));

% Concert the cell format into matrix format for matrix computation.
C=zeros(n_link,n_link);
for i=n_link
    for j=1:n_link
        C(i,j)=(C_element.theta(i,j));
    end
end
p_x.theta=double(subs(p_x.theta,theta,q));
p_y.theta=double(subs(p_y.theta,theta,q));
Pg=zeros(n_link,1); Pk=zeros(n_link,1); Pb=zeros(n_link,1);
for i=1:n_link
    P_g(i).theta=double(subs(P_g(i).theta,theta,q));
    Pg(i,1)=P_g(i).theta;
    Pk(i,1)=double(k(i)*q(i));
    Pb(i,1)=double(b(i)*dq(i));
end