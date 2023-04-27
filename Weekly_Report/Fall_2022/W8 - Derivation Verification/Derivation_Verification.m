clear all; clc;

format short;
n_link=2;
theta=sym('theta',[1,n_link]);
l=sym('l',[1,n_link]);
m=sym('m',[1,n_link]);
g=9.81;
R=struct('link',zeros(4,4),'joint',zeros(4,4));

% As the precision of pi value has caused some problems when do
% calculations about rotation matrices, we need to redefine the value for
% sin(pi/2) and cos(pi/2).

% R10=[cos(-theta(1)) -sin(-theta(1)) 0 0;
%     sin(-theta(1)) cos(-theta(1)) 0 0;
%     0 0 1 0;
%     0 0 0 1]*[1 0 0 0;
%     0 cos(-pi/2) -sin(-pi/2) 0;
%     0 sin(-pi/2) cos(-pi/2) 0;
%     0 0 0 1];

R(1).link=[cos(-theta(1)) -sin(-theta(1)) 0 0;
    sin(-theta(1)) cos(-theta(1)) 0 0;
    0 0 1 0;
    0 0 0 1]*[1 0 0 0;
    0 0 1 0;
    0 -1 0 0;
    0 0 0 1];

% R21=[1 0 0 0;
%     0 1 0 0;
%     0 0 1 l(1);
%     0 0 0 1]*[1 0 0 0;
%     0 cos(pi/2) -sin(pi/2) 0;
%     0 sin(pi/2) cos(pi/2) 0;
%     0 0 0 1];

R(2).link=[1 0 0 0;
    0 1 0 0;
    0 0 1 l(1);
    0 0 0 1]*[1 0 0 0;
    0 0 -1 0;
    0 1 0 0;
    0 0 0 1];

% R32=[cos(-(theta(2)-theta(1))) -sin(-(theta(2)-theta(1))) 0 0;
%     sin(-(theta(2)-theta(1))) cos(-(theta(2)-theta(1))) 0 0;
%     0 0 1 0;
%     0 0 0 1]*[1 0 0 0;
%     0 cos(-pi/2) -sin(-pi/2) 0;
%     0 sin(-pi/2) cos(-pi/2) 0;
%     0 0 0 1];

R(3).link=[cos(-(theta(2)-theta(1))) -sin(-(theta(2)-theta(1))) 0 0;
    sin(-(theta(2)-theta(1))) cos(-(theta(2)-theta(1))) 0 0;
    0 0 1 0;
    0 0 0 1]*[1 0 0 0;
    0 0 1 0;
    0 -1 0 0;
    0 0 0 1];

R(4).link=[1 0 0 0;
    0 1 0 0;
    0 0 1 l(2);
    0 0 0 1];

% for i=1:4
%     for j=1:4
%         try
%             a=double(R10(i,j));
%         catch
%             m1=coeffs(R10(i,j),sin(theta(1)));
%             m2=coeffs(R10(i,j),cos(theta(1)));
%                 if length(m1)==1
%                     m1=double(m1);
%                     if m1<=10^-6
%                         R10(i,j)=0;
%                     else
%                         R10(i,j)=m1*sin(theta(1));
%                     end
%                 else
%                     m1_sum=0;
%                     for i=1:length(m1)
%                         try
%                             m1_multi(i)=double(m1(i));
%                             if m1_multi(i)<=10^-6
%                                 m1_sum=m1_sum;
%                             else
%                                 m1_sum=m1_sum+m1_multi*sin(theta(i));
%                             end
%                         catch
%                             m1_sum=m1_sum+m1(i);
%                         end
%                     end
%                 end
%         end
%     end
% end

for i=1:n_link
    if i==1
        R(i).joint=simplify(R(2*i-1).link*R(2*i).link);
    else
        R(i).joint=simplify(R(i-1).joint*R(2*i-1).link*R(2*i).link);
    end
end

% Calculate the COM of each link
for i=1:n_link
    p(:,i)=R(i).joint(1:3,4);
end
pc=cell(1,n_link);
for i=1:n_link
    if i==1
        pc{1,i}=1/2*p(:,i);
    else
        pc{1,i}=p(:,i-1)+1/2*(p(:,i)-p(:,i-1));
    end
end

J=struct('v',zeros(3,n_link),'w',zeros(3,n_link));
% Calculate the linear part of body Jacobian
for i=1:n_link
    J(i).v=jacobian(pc{i},theta);
end

% Calculate the angualr part of body Jacobian
R_3by3=struct('theta',zeros(3,3),'theta_intm',zeros(4,4),'dot',cell(3,3),'w_intm',zeros(3,3*n_link),'w',zeros(3,3));
for i=1:n_link
    R_3by3(i).theta=R(i).joint(1:3,1:3);
end
% 2022.10.12
% First trial, not correct, the angualr velocity should still be based on
% the joint state.
% for i=1:n_link
%     if i==1
%         R_3by3(i).theta=simplify(R(2*i-1).link(1:3,1:3));
%     else
%         R_3by3(i-1).theta_intm=R(i).joint*R(2*i-1).link;
%         R_3by3(i).theta=simplify(R_3by3(i-1).theta_intm(1:3,1:3));
%     end
% end

%% The angular velocity calculated by using the properties of skew symmetric matrix is not correct.
% theta_dot=sym('theta_dot',[1,n_link]);
% for i=1:n_link
%     for j=1:3
%         J(i).w_intm(:,2*j-1:2*j)=jacobian(R_3by3(i).theta(j,:),theta);
%     end
% end
% for i=1:n_link
%     for j=1:3
%         for k=1:3
%             R_3by3(i).dot{j,k}=[J(i).w_intm(j,2*k-1) J(i).w_intm(j,2*k)]*[transpose(theta_dot)];
%         end
%     end
% end
% for i=1:n_link
%     R_3by3(i).w=R_3by3(i).dot*transpose(R_3by3(i).theta);
% end
% w=struct('vector',zeros(3,1));
% for i=1:n_link
%     w(i).vector=simplify([R_3by3(i).w(3,2);
%         R_3by3(i).w(1,3);
%         R_3by3(i).w(2,1)]);
% end
% % This is not the real angular Jacobian, the matrix worked out below is
% % already multiplied by the rotation matrix.
% for i=1:n_link
%     J(i).w=jacobian(w(i).vector,theta_dot);
% %     simplify(transpose(J(i).w)*J(i).w)
% end

theta_dot=sym('theta_dot',[1,n_link]);
w=struct('vector',zeros(3,1));
for i=1:n_link
    w(i).vector=R(i).joint(1:3,3)*theta_dot(i);
end
for i=1:n_link
    J(i).w=jacobian(w(i).vector,theta_dot);
end

% Inertia Matrix calculation
M_temp=struct('theta',zeros(n_link,n_link),'sum',zeros(n_link,n_link));
for i=1:n_link
    M_temp(i).theta=simplify(m(i)*transpose(J(i).v)*J(i).v+1/12*m(i)*(l(i))^2*transpose(J(i).w)*J(i).w);
end
for i=1:n_link
    if i==1
        M_temp(i).sum=M_temp(i).theta;
    else
        M_temp(i).sum=M_temp(i-1).sum+M_temp(i).theta;
    end
end
M=simplify(M_temp(end).sum);

% Coriolis Matrix Calculation
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
        C(i,j)=simplify(C_element{i,j});
    end
end

% Potential Energy Term Calculation
P=struct('g',zeros(n_link,1),'g_link',zeros(1,1));
for i=1:n_link
    P(i).g_link=pc{i};
    P(i).g=-1*m(i)*P(i).g_link(2);
end
for i=1:n_link
    Pg(i)=P(i).g*g;
end
Pg=transpose(Pg);

%% Optional Part %%
% Examine the reasonablity of the inertia matrix.
% Using the property of skew symmetric matrix, we need first to work out
% the M_dot matrix.
for i=1:n_link
    for j=1:n_link
        param=jacobian(M(i,j),theta);
        for k=1:n_link
            if k==1
                M_dot_element{i,j}=param(k)*theta_dot(k);
            else
                M_dot_element{i,j}=M_dot_element{i,j}+param(k)*theta_dot(k);
            end
        end
    end
end
for i=1:n_link
    for j=1:n_link
        M_dot(i,j)=simplify(M_dot_element{i,j});
    end
end
N=simplify(M_dot-2*C);
minus_one=simplify(inv(N)*(N));
eigenvalue_M=simplify(eig(M));
eigenvalue_M_upper=subs(eigenvalue_M,cos(2*(theta(1)-theta(2))),1);
eigenvalue_M_lower=subs(eigenvalue_M,cos(2*(theta(1)-theta(2))),-1);

