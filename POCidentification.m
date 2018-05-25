function POCidentification
%Loads output of POC_tracks_alignment
load('POC_tracks_alignment_data_2018_05_25.mat')

%Takes the data input, and forms the matricies used in future calculations
[omega,T] = create_matricies(a_o1,a_o2,a_o3,a_o4,a_fz,a_tx,a_ty,a_tz);

%Span to calculate coefficients over
n1 = [2134,3246,4779,5567,7371,17750,19090,24350,25890,30200,31200];
n2 = [3045,4696,5331,7336,17410,18710,24240,25480,30130,31040,36060];
len_n1 = length(n1);
len_n2 = length(n2);

%Solves for the coefficients and then uses them to check theoretical versus
%actual. This is where we see if it is truly a linear system
[coef,coef_ave] = combined_coefficients(omega,T,n1,n2,len_n1,len_n2);
use_coefficients(coef,coef_ave,omega,a_fz,a_tx,a_ty,a_tz,n1,n2,len_n1)

%Plot coefficients to check for trends
plot_coefficients(coef,coef_ave)

print_stars()
%Calculate and plot coefficients for the entire data set assuming combined
%coefficients
combined_whole_dataset(omega,T,a_fz,a_tx,a_ty,a_tz)

%Stars for clarity
print_stars()

%Furthering the calculations, here a larger matrix is created that solves
%for the coefficients of each motor
independent_coef = independent_coefficients(omega,T,n1,n2,len_n1);
use_independent(independent_coef,omega,a_fz,a_tx,a_ty,a_tz,n1,n2,len_n1)
plot_independent_coef(independent_coef)



%Initialize the matricies
function [omega,T] = create_matricies(a_o1,a_o2,a_o3,a_o4,a_fz,a_tx,a_ty,a_tz)
omega = [a_o1;a_o2;a_o3;a_o4];
T = [a_fz;a_tx;a_ty;a_tz];

%Calculates the coefficient matricies assuming they are uniform throughout
%the 4 motors. 
function [coef,coef_ave] = combined_coefficients(omega,T,n1,n2,len_n1,len_n2)
omega_mat = [];
T_mat = [];

for i = 1:len_n1
    for iN = n1(i):n2(i)
        osq = omega(:,iN).^2;
        Ti = T(:,iN);
        mat_o = [sum(osq),0,0;0,osq(1)-osq(2)+osq(3)-osq(4),0;0,-osq(1)+osq(2)+osq(3)-osq(4),0;0,0,-osq(1)+osq(2)-osq(3)+osq(4)];
        %mat_T = Ti;
        
        omega_mat(end+1:end+4,(3*i-2):(i*3)) = mat_o;
        T_mat(end+1:end+4,i) = Ti;
    end
end

%looping and solving for coefficients at each horizontal
coef = [];
for j = 1:len_n1
    fprintf('\n<< Linear system solution for %d - %d >>\n',n1(j),n2(j))
    coef = [coef,(omega_mat(:,(3*j-2):(3*j))\T_mat(:,j))];
    print_coefficients('combined',coef(:,j))
end

print_stars()
%Looping and using the average method to solve for coefficients at each
%horizontal
coef_ave = [];
for m = 1:len_n1
    denominator = n2(m) - n1(m);
    for k = 1:4
        T_ave(k,m) = sum(T_mat(k:4:end,m))/(denominator);
        omega_index = (3*m-2);
        omega_ave(k,omega_index) = sum(omega_mat(k:4:end,omega_index))/(denominator);
        omega_ave(k,omega_index+1) = sum(omega_mat(k:4:end,omega_index+1))/(denominator);
        omega_ave(k,omega_index+2) = sum(omega_mat(k:4:end,omega_index+2))/(denominator);
    end
    
    fprintf('\n<< Averaging solution for %d - %d >>\n',n1(m),n2(m))
    coef_ave = [coef_ave,(omega_ave(:,(3*m-2):(3*m))\T_ave(:,m))];
    print_coefficients('combined',coef_ave(:,m))
end

function use_coefficients(coef,coef_ave,omega,a_fz,a_tx,a_ty,a_tz,n1,n2,len_n1)
%fig = figure('Visible','on','Name','Check Coefficients');
for i = 1:len_n1
    T_plot = [];
    T_av_plot = [];
    
    ct = coef(1,i);
    dct = coef(2, i);
    cq = coef(3,i);
    av_ct = coef_ave(1,i);
    av_dct = coef_ave(2,i);
    av_cq = coef_ave(3,i);
    
    coef_mat = [ct,ct,ct,ct;dct,-dct,dct,-dct;-dct,dct,dct,-dct;-cq,cq,-cq,cq];
    av_coef_mat = [av_ct,av_ct,av_ct,av_ct;av_dct,-av_dct,av_dct,-av_dct;-av_dct,av_dct,av_dct,-av_dct;-av_cq,av_cq,-av_cq,av_cq];
    
    for iN = 1:length(omega)
        osq = omega(:,iN).^2;
        T = coef_mat * osq;
        T_av = av_coef_mat * osq;
        
        T_plot = [T_plot,T];
        T_av_plot = [T_av_plot,T_av];
    end
    figure('Visible','on','Name','Check Coefficients')
    title = sprintf('Matrix Determined %d - %d',n1(i),n2(i));
    mat_det = uitab('Title',title);
    mat_ax = axes(mat_det);
    title2 = sprintf('Average Determined %d - %d',n1(i),n2(i));
    av_det = uitab('Title',title2);
    av_ax = axes(av_det);
    
    time = 1:length(T_plot(1,:));
    
    mat = plot(mat_ax,time,T_plot(1,:),time,T_plot(2,:),time,T_plot(3,:),time,T_plot(4,:),time,a_fz,time,a_tx,time,a_ty,time,a_tz);
    legend(mat,'Calculated Fz','Calculated Tx','Calculated Ty','Calculated Tz','Force Z','Torque X','Torque Y','Torque Z','Orientation','horizontal')
    
    av = plot(av_ax,time,T_av_plot(1,:),time,T_av_plot(2,:),time,T_av_plot(3,:),time,T_av_plot(4,:),time,a_fz,time,a_tx,time,a_ty,time,a_tz);
    legend(av,'Calculated Fz','Calculated Tx','Calculated Ty','Calculated Tz','Force Z','Torque X','Torque Y','Torque Z','Orientation','horizontal')
end

function plot_coefficients(coef,coef_ave)
figure('Visible','on','Name','Plotted Coefficients')
t = 1:length(coef(1,:));

tab = uitab('Title','Coefficients');
ax = axes(tab);
coef_plot = plot(ax,t,coef(1,:),'b',t,coef(2,:),'k',t,coef(3,:),'r',t,coef_ave(1,:),'b--+',t,coef_ave(2,:),'k--',t,coef_ave(3,:),'r--');
legend(coef_plot,'Ct','dCt','cq','ave_Ct','ave_dCt','ave_cq')

% tab2 = uitab('Title','Average Coefficients');
% ax_average = axes(tab2);
% coef_ave_plot = plot(ax_average,t,coef_ave(1,:),t,coef_ave(2,:),t,coef_ave(3,:));
% legend(coef_ave_plot,'Ct','dCt','cq')

tab2 = uitab('Title','dct/ct');
ax2 = axes(tab2);
coef_plot2 = plot(ax2,t,coef(1,:),'b',t,coef(2,:),'k',t,(coef(2,:)./coef(1,:)),'r');
legend(coef_plot2,'ct','dct','dct/ct')

function combined_whole_dataset(omega,T,a_fz,a_tx,a_ty,a_tz)
omega_mat = [];
T_mat = [];

for iN = 1:length(omega)
    osq = omega(:,iN).^2;
    Ti = T(:,iN);
    mat_o = [sum(osq),0,0;0,osq(1)-osq(2)+osq(3)-osq(4),0;0,-osq(1)+osq(2)+osq(3)-osq(4),0;0,0,-osq(1)+osq(2)-osq(3)+osq(4)];
    %mat_T = Ti;
    
    omega_mat = [omega_mat;mat_o];
    T_mat = [T_mat;Ti];
end

%Solve for coefficients
coef = omega_mat\T_mat;
fprintf('\n<< Linear system solution for entire data set >>\n')
print_coefficients('combined',coef)

%Lets use the calculated coefficient matrix to solve for the F/Ts and compare to experimental results

T_plot = [];

ct = coef(1);
dct = coef(2);
cq = coef(3);

coef_mat = [ct,ct,ct,ct;dct,-dct,dct,-dct;-dct,dct,dct,-dct;-cq,cq,-cq,cq];

for iN = 1:length(omega)
    osq = omega(:,iN).^2;
    T = coef_mat * osq;
   
    T_plot = [T_plot,T];
end
figure('Visible','on','Name','Check Coefficients Over Whole Set')
title = sprintf('Matrix Determined over entire set');
mat_det = uitab('Title',title);
mat_ax = axes(mat_det);

time = 1:length(T_plot(1,:));

mat = plot(mat_ax,time,T_plot(1,:),time,T_plot(2,:),time,T_plot(3,:),time,T_plot(4,:),time,a_fz,time,a_tx,time,a_ty,time,a_tz);
legend(mat,'Calculated Fz','Calculated Tx','Calculated Ty','Calculated Tz','Force Z','Torque X','Torque Y','Torque Z','Orientation','horizontal')

function independent_coef = independent_coefficients(omega,T,n1,n2,len_n1)
independent_coef = [];
for i = 1:len_n1
    omega_mat = [];
    T_mat = [];
    for iN = n1(i):n2(i)
        osq = omega(:,iN).^2;
        Ti = T(:,iN);
        mat_o = [osq(1),osq(2),osq(3),osq(4),0,0,0,0,0,0,0,0;
            0,0,0,0,osq(1),-osq(2),osq(3),-osq(4),0,0,0,0;
            0,0,0,0,-osq(1),osq(2),osq(3),-osq(4),0,0,0,0;
            0,0,0,0,0,0,0,0,-osq(1),osq(2),-osq(3),osq(4)];
        
        omega_mat = [omega_mat;mat_o];
        T_mat = [T_mat;Ti];
    end
    
    fprintf('\n<< Independent Values for %d - %d >>\n',n1(i),n2(i))
    independent_coef = [independent_coef,(omega_mat\T_mat)];
    print_coefficients('all',independent_coef)
end

function use_independent(independent_coef,omega,a_fz,a_tx,a_ty,a_tz,n1,n2,len_n1)

for i = 1:len_n1
    
    T_plot = [];
    
    ct1 = independent_coef(1,i);
    ct2 = independent_coef(2,i);
    ct3 = independent_coef(3,i);
    ct4 = independent_coef(4,i);
    dct1 = independent_coef(5,i);
    dct2 = independent_coef(6,i);
    dct3 = independent_coef(7,i);
    dct4 = independent_coef(8,i);
    cq1 = independent_coef(9,i);
    cq2 = independent_coef(10,i);
    cq3 = independent_coef(11,i);
    cq4 = independent_coef(12,i);
    
    coef_mat = [ct1,ct2,ct3,ct4;dct1,-dct2,dct3,-dct4;-dct1,dct2,dct3,-dct4;-cq1,cq2,-cq3,cq4];
    
    for iN = 1:length(omega)
        osq = omega(:,iN).^2;
        T = coef_mat * osq;
        
        T_plot = [T_plot,T];
    end
    
    figure('Visible','on','Name','Check Independent Coefficients')
    title = sprintf('Matrix Determined %d - %d',n1(i),n2(i));
    mat_det = uitab('Title',title);
    mat_ax = axes(mat_det);
    
    time = 1:length(T_plot(1,:));
    
    mat = plot(mat_ax,time,T_plot(1,:),time,T_plot(2,:),time,T_plot(3,:),time,T_plot(4,:),time,a_fz,time,a_tx,time,a_ty,time,a_tz);
    legend(mat,'Calculated Fz','Calculated Tx','Calculated Ty','Calculated Tz','Force Z','Torque X','Torque Y','Torque Z','Orientation','horizontal')
    
end

function plot_independent_coef(independent_coef)
figure('Visible','on','Name','Plotted Independent Coefficients')
t = 1:length(independent_coef(1,:));

tab_ct = uitab('Title','CT');
ax_ct = axes(tab_ct);
plot(ax_ct,t,independent_coef(1,:),t,independent_coef(2,:),t,independent_coef(3,:),t,independent_coef(4,:));

tab_dct = uitab('Title','dCT');
ax_dct = axes(tab_dct);
plot(ax_dct,t,independent_coef(5,:),t,independent_coef(6,:),t,independent_coef(7,:),t,independent_coef(8,:));

tab_cq = uitab('Title','CQ');
ax_cq = axes(tab_cq);
plot(ax_cq,t,independent_coef(9,:),t,independent_coef(10,:),t,independent_coef(11,:),t,independent_coef(12,:));

tab_div = uitab('Title','dct/ct');
ax_div = axes(tab_div);
plot(ax_div,t,(independent_coef(8,:)./independent_coef(4,:)),t,(independent_coef(7,:)./independent_coef(3,:)),t,(independent_coef(6,:)./independent_coef(2,:)),t,(independent_coef(5,:)./independent_coef(1,:)));

function print_stars()
fprintf('\n*************************************************************\n')



% [U,S,V] = svd(omega_mat,'econ');
% s = diag(S);
% d = U'*T_mat;
% coef2 = V*([d(1:3)./s(1:3)]); %;zeros(length(T_mat)-3,1)])
% disp(coef2)

