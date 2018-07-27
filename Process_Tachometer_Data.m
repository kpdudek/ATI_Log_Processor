function Process_Tachometer_Data
load('sensor_data.mat')
%load('num_peaks.mat')

plot_data(rpm,omega,sl_pty)


rpm_cut=rpm(100:263);
omega_cut=omega(4,1000:2695);
test_linear(omega_cut,rpm_cut)


%%%  Values for the number of peaks to crop after for the indicator
%%%  portions
r = 5; %RPM
o = 5; %Omega plot (PX4)
t = 5; %Torque
[omega_init,rpm_init,ty_init,omega_locs,rpm_locs,ty_locs] = find_peaks(omega(2,:),rpm,sl_pty,r,o,t);

shift_omega = 0;
shift_rpm = 0;
[rpm_offset,omega_offset] = align_data(rpm_init,omega_init,ty_init,shift_omega,shift_rpm);

% manual_shift()

%save('num_peaks','r','o','t')




%Function that plots the raw data
function plot_data(rpm,omega,ty)
len_rpm = 1:length(rpm);
len_omega = 1:length(omega(1,:));
len_ft = 1:length(ty);

figure('Visible','on','Name','RPM')
plot(len_rpm,rpm)

figure('Visible','on','Name','Omega')
o1 = uitab('Title','Motor 1');
o1ax = axes(o1);
plot(o1ax,len_omega,omega(1,:))
o2 = uitab('Title','Motor 2');
o2ax = axes(o2);
plot(o2ax,len_omega,omega(2,:))
o3 = uitab('Title','Motor 3');
o3ax = axes(o3);
plot(o3ax,len_omega,omega(3,:))
o4 = uitab('Title','Motor 4');
o4ax = axes(o4);
plot(o4ax,len_omega,omega(4,:))
all = uitab('Title','All');
allax = axes(all);
plot(allax,len_omega,omega(1,:),len_omega,omega(2,:),len_omega,omega(3,:),len_omega,omega(4,:))

figure('Visible','on','Name','Ty')
plot(len_ft,ty)

%Function that resamples the rpm data, and then scales the corresponding
%omega plot to check if its linear
function test_linear(omega,rpm)
len_omega = length(omega);
len_rpm = length(rpm);
t = 1:len_omega;

rpm = interp1(1:len_rpm,rpm,linspace(1,len_rpm,len_omega));
%rpm = resample(rpm,len_omega,len_rpm);

figure('Name','RPM Scaling')
plot(t,omega*6.7857,t,rpm)
ylabel('Note: pixhawk reading is manually scaled')
figure('Name','RPM Scaling Scatter')
%scatter(omega,rpm)
mdl=fitlm(omega,rpm);
plot(mdl)
q=table2array(mdl.Coefficients(1,'Estimate'));
p=table2array(mdl.Coefficients(2,'Estimate'));
figure('Name','RPM After Fit')
plot(t,omega*p+q,t,rpm)


%%%%%    The data set is now being aligned    %%%%%

%Function that pulls out the indicator portions by isolating the first n
%peaks,
function [omega_init,rpm_init,ty_init,omega_locs,rpm_locs,ty_locs] = find_peaks(omega,rpm,ty,r,o,t)
figure('Visible','on','Name','Peaks')

tab_s1 = uitab('Title','Actuator Output 2');
ax_s1 = axes(tab_s1);
t1 = 1:length(omega);
plot(ax_s1,t1,omega)
hold on
[pks1,omega_locs] = findpeaks(omega,'MinPeakHeight',1350,'MinPeakDistance',35);
plot(ax_s1,t1(omega_locs),pks1,'ko')

tab_s2 = uitab('Title','Filtered Force Y');
ax_s2 = axes(tab_s2);
t2 = 1:length(ty);
plot(ax_s2,t2,ty)
hold on
[pks2,ty_locs] = findpeaks(ty,'MinPeakHeight',.3,'MinPeakDistance',350);
plot(ax_s2,t2(ty_locs),pks2,'ko')

tab_s3 = uitab('Title','RPM');
ax_s3 = axes(tab_s3);
t3 = 1:length(rpm);
plot(ax_s3,t3,rpm)
hold on
[pks3,rpm_locs] = findpeaks(rpm,'MinPeakHeight',8600,'MinPeakDistance',2);
plot(ax_s3,t3(rpm_locs),pks3,'ko')

omega_init = omega(1:(omega_locs(o)+40));
ty_init = ty(1:(ty_locs(t)+200));
rpm_init = rpm(1:(rpm_locs(r)+4));

%Align the rpm dataset and the pixhawk dataset to the FT set. Since the FT
%set is the highest samplerate, the RPM/PX4 have to be resampled
function [rpm_offset,omega_offset] = align_data(rpm,omega,ty,shift_omega,shift_rpm)
%Beginning of the signal analysis
c_rpm = condition(rpm);
c_omega = condition(omega);
c_ty = condition(ty);

%Setup of variables for use in looping for best resample and offset
lags=1:100;
Nlags=length(lags);

%Empty matrix to contain correlation between data
scores=[];

%Running data to find best correlation and the indexes for offset and lag
score_max = 0;
Lags = [];

%Looping to find correlation at varying offsets and lags
ft_length = length(c_ty);
rotor_length = length(c_omega);
rpm_length = length(c_rpm);


omega_resamp = interp1(1:rotor_length,c_omega,linspace(1,rotor_length,ft_length))';
rpm_resamp = interp1(1:rpm_length,c_rpm,linspace(1,rpm_length,ft_length))';
% omega_resamp = resample(c_omega,ft_length,rotor_length);
% rpm_resamp = resample(c_rpm,ft_length,rpm_length);

for iLags=1:Nlags
    for jLags=1:Nlags
        for kLags=1:Nlags
            
            score = align_score(omega_resamp,rpm_resamp,c_ty,lags(iLags),lags(jLags),lags(kLags));
            scores = [scores,score];
            
            if score > score_max
                score_max = score;
                Lags = [iLags,jLags,kLags]; % omega , rpm , FT
            end
        end
    end
end
%Processing the output of the looping
[rpm_offset,omega_offset,ty_offset] = surf_scores(scores,Lags,lags);
check_alignment(omega_resamp,rpm_resamp,c_ty,Lags)





%Conditions the data to a 0 though 1 scale
function s_conditioned=condition(s)
s=shiftdim(s);
sMax=max(s);
sMin=min(s);
s_conditioned=(s-sMin)/(sMax-sMin);

%Function that offsets the dataset and then calculates the correlation 
function score=align_score(omega_resamp,rpm_resamp,c_ty,iLag,jLag,kLag)
lag_set = [iLag,jLag,kLag];
[ft_lag,omega_lag,rpm_lag] = lag_sets(omega_resamp,rpm_resamp,c_ty,lag_set);

score = correlation(ft_lag,omega_lag,rpm_lag);

function [ft_lag,omega_lag,rpm_lag] = lag_sets(omega_resamp,rpm_resamp,c_ty,lags)
omega_lag = omega_resamp(lags(1)+1:end);
rpm_lag = rpm_resamp(lags(2)+1:end);
ft_lag = c_ty(lags(3)+1:end);



%Crops the data set to the specified lag
function [s1_lag,s2_lag] = lag_signals(s1,s2,lag)
if lag>0
    s1_lag=s1;
    s2_lag=s2(lag+1:end);
elseif lag<0
    s1_lag=s1(-lag+1:end);
    s2_lag=s2;
else
    s1_lag=s1;
    s2_lag=s2;
end

%Finds the correlation between the data sets
function c = correlation(ft_lag,omega_lag,rpm_lag)
N = min([length(ft_lag),length(omega_lag),length(rpm_lag)]);
c = sum(ft_lag(1:N).*omega_lag(1:N).*rpm_lag(1:N));

%Takes the raw datasets and offsets them by the calculated lag in
%align_data()
function [a_FT,a_Omega,a_RPM] = aligned_data(ft,omega,rpm,rpm_offset,omega_offset,omega_locs,rpm_locs,ty_locs,r,o,t)

%determine which dataset starts first
if (rpm_offset > 0) && (omega_offset > 0) && (comp_offset > 0) %ggg
    %rpm first
elseif (rpm_offset < 0) && (omega_offset < 0) && (comp_offset < 0) %lll
    %ATI first
elseif (rpm_offset > 0) && (omega_offset < 0) && (comp_offset > 0) %glg
    %rpm first
elseif (rpm_offset > 0) && (omega_offset < 0) && (comp_offset < 0) %gll
    %rpm first
elseif (rpm_offset < 0) && (omega_offset > 0) && (comp_offset > 0) %lgg
    %omega first
elseif (rpm_offset < 0) && (omega_offset < 0) && (comp_offset > 0) %llg
    %ATI first
elseif (rpm_offset > 0) && (omega_offset > 0) && (comp_offset < 0) %ggl
    %omega first
elseif (rpm_offset < 0) && (omega_offset > 0) && (comp_offset > 0) %lgg
    %omega first
elseif (rpm_offset < 0) && (omega_offset > 0) && (comp_offset < 0) %lgl
    %omega first
end
















FT_length = length(ffz);
rotor_length = length(o1);
so1 = resample(o1,FT_length,rotor_length);
so2 = resample(o2,FT_length,rotor_length);
so3 = resample(o3,FT_length,rotor_length);
so4 = resample(o4,FT_length,rotor_length);

if offset > 0
    a_fz = ffz((offset+1)+(locs2(3)+300):end);
    a_tx = ftx(offset+1+(locs2(3)+300):end);
    a_ty = fty(offset+1+(locs2(3)+300):end);
    a_tz = ftz(offset+1+(locs2(3)+300):end);
    a_o1 = so1(1+(locs2(3)+300):end);
    a_o2 = so2(1+(locs2(3)+300):end);
    a_o3 = so3(1+(locs2(3)+300):end);
    a_o4 = so4(1+(locs2(3)+300):end);
elseif offset < 0
    a_fz = ffz(1+(locs2(3)+300):end);
    a_tx = ftx(1+(locs2(3)+300):end);
    a_ty = fty(1+(locs2(3)+300):end);
    a_tz = ftz(1+(locs2(3)+300):end);
    a_o1 = so1((-offset+1)+(locs2(3)+300):end);
    a_o2 = so2((-offset+1)+(locs2(3)+300):end);
    a_o3 = so3((-offset+1)+(locs2(3)+300):end);
    a_o4 = so4((-offset+1)+(locs2(3)+300):end);
else
    a_fz = ffz((locs2(3)+300):end);
    a_tx = ftx((locs2(3)+300):end);
    a_ty = fty((locs2(3)+300):end);
    a_tz = ftz((locs2(3)+300):end);
    a_o1 = so1((locs2(3)+300):end);
    a_o2 = so2((locs2(3)+300):end);
    a_o3 = so3((locs2(3)+300):end);
    a_o4 = so4((locs2(3)+300):end);
end

[locs1,locs2] = end_peaks(a_o2,a_ty);

a_o1 = a_o1(1:locs1(end)+50);
a_o2 = a_o2(1:locs1(end)+50);
a_o3 = a_o3(1:locs1(end)+50);
a_o4 = a_o4(1:locs1(end)+50);
a_fz = a_fz(1:locs2(end)+50);
a_tx = a_tx(1:locs2(end)+50);
a_ty = a_ty(1:locs2(end)+50);
a_tz = a_tz(1:locs2(end)+50);

FT_length = length(a_fz);
rotor_length = length(a_o1);
out_o1 = resample(a_o1,FT_length,rotor_length);
out_o2 = resample(a_o2,FT_length,rotor_length);
out_o3 = resample(a_o3,FT_length,rotor_length);
out_o4 = resample(a_o4,FT_length,rotor_length);

%Pulls out the greatest correlation and the corresponding index value that
%will be used to align the raw datasets
function [rpm_offset,omega_offset,ty_offset] = surf_scores(scores,Lags,lags)
POC_plot = figure('Visible','on','Name','FT & PX4 Offset');
%len = 1:length(scores(1,:));
plot(scores)
%legend('PX4 Correlation','RPM Correlation')

rpm_offset = lags(Lags(2));
rpm_offset_ind = Lags(2);
fprintf('RPM Offset(index): %f - Offset: %f\n',rpm_offset_ind,rpm_offset)

omega_offset = lags(Lags(1));
omega_offset_ind = Lags(1);
fprintf('Omega Offset(index): %f - Offset: %f\n',omega_offset_ind,omega_offset)

ty_offset = lags(Lags(3));

%Plots aligned data to visually check alignment
function check_alignment(omega_resamp,rpm_resamp,c_ty,Lags)
figure('Visible','on','Name','Alignment')
[ft,omega,rpm] = lag_sets(omega_resamp,rpm_resamp,c_ty,Lags);
plot(rpm)
hold on
plot(omega)
hold on
plot(ft)

% 
% function [rpm_out,omega_out] = manual_shift(rpm,omega,ty,omega_shift,rpm_shift)
% [rpm_temp = lag_signals(rpm,ty,rpm_shift);
% omega_temp = lag_signals(omega,ty,omega_shift);














