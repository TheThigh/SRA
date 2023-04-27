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

% The cell array cannot be accepted or coded in Simulink, we can use struct
% instead.
theta=sym('theta',[1,n_link]);
for i=1:n_link
    % The expression of the standand derived transformation/rotation
    % matrix.
    R_theta{i}=[cos(theta(i)) sin(theta(i)) 0 2*L(i)*(sin(theta(i)/2))^2/theta(i);
    -sin(theta(i)) cos(theta(i)) 0 L(i)*sin(theta(i))/theta(i);
    0 0 1 0;
    0 0 0 1];
end

% Calculate the intermediate rotation matrix.
for j=1:n_link
    if j==1
        R_intm{j}=R_theta{1};
    else
        R_intm{j}=R_intm{j-1}*R_theta{j};
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
for i=1:n_link
    R_pos=Rz_down*R_intm{i};
    p_x(i)=R_pos(1,4);
    p_y(i)=R_pos(2,4);
end
delta_p_y(1)=p_x(1)-pfx;
delta_p_x(1)=p_y(1)-pfy;
for i=2:n_link
    delta_p_y(i)=p_x(i)-p_x(i-1);
    delta_p_x(i)=p_y(i)-p_y(i-1);
end
% Calculate the absolute distance between the original inertia frame and
% the COM of each link.
potential_g_y(1)=delta_p_y(1)/2;
for i=2:n_link
    potential_g_y(i)=p_y(i-1)+delta_p_y(i)/2;
end

% Calculate the manipulator Jacobian matrix
o{1}=[pfx;pfy;0];
z{1}=[0;0;1];
for i=1:n_link
    o{i+1}=[p_x(i);p_y(i);0];
    R_pos=Rz_down*R_intm{i};
    z{i+1}=[R_pos(1,3);R_pos(2,3);R_pos(3,3)];
end
for i=1:n_link
    J_v{i}=cross(z{i},o{end}-o{i});
    J_w{i}=z{i};
end

% Kinetic Energy Calculation

% Potential Energy Calculation, which is based on the Lagrange's Equation.
% We don't have to work out the part due to stiffness and damping as they
% are about theta and theta dot respectively.
P_g_real=0;
for i=1:n_link
    P_g_real=P_g_real+m(i)*g*potential_g_y(i);
end
for i=1:n_link
    P_g(i)=diff(P_g_real,theta(i));
end

% Intertia Matrix
for i=1:n_link
    R_pos=Rz_down*R_intm{i};
    J_linear{i}=jacobian([R_pos(1,4),R_pos(2,4)],theta);
    M_linear{i}=m(i)*transpose(J_linear{i})*J_linear{i};
    I(i)=1/12*m(i)*(L(i))^2;
    J_angular=zeros(1,n_link);
    J_angular(1:i)=1;
    M_angular{i}=I(i)*1/2*transpose(J_angular)*1/2*J_angular;
    M_total{i}=M_linear{i}+M_angular{i};
end
M=M_total{1};
for i=2:n_link
    M=M+M_total{i};
end

% Centripetal-Coriolis Matrix

theta_dot=sym('theta_dot',[1,n_link]);
sum_element=0;
for i=1:n_link
    for j=1:n_link
        C{i,j}=0;
    end
end
for i=1:n_link
    for j=1:n_link
        for k=1:n_link
            sum_intm(k)=1/2*(diff(M(i,j),theta(k))+diff(M(i,k),theta(j))-diff(M(k,j),theta(i)))*theta_dot(k);
            sum_element=sum_element+sum_intm(k);
        end
        C{i,j}=sum_element;
    end
end
eigv_M=simplify(eig(M));