function lsnonlintest
load('POCidentification_all_coefs_2018_06_01_4Corners_Acro.mat')
load('POCidentification_test_span_2018_06_01_4Corners_Acro.mat')

fitted_coefs = [];

for i = 1:length(coef)
    ct = coef(1,i);
    d = coef(2,i)/coef(1,i);
    
    coef_0 = [ct;d];
    FT_true = T;%(:,i);
    
    %FTmeasured = model(omega,coef);
    fitted_coefs = [fitted_coefs,(lsqnonlin(@(x) residuals(FT_true,omega,x),coef_0))];
    fprintf('Estimated: ct = %e -- d = %f\nFitted: ct = %e -- d = %f\n',ct,d,fitted_coefs(1),fitted_coefs(2))
end

plot_coef_vs_fitted(coef,fitted_coefs)

use_LS_values(fitted_coefs,omega,T)

ct_vs_omega(omega,coef,n1,n2)


function f = residuals(FT_true,omega,x)
f = [];
for i = 1:length(omega)
    f = [f,(FT_true(1:3,i)-model(omega(:,i),x))];
end

function ft = model(omega,x)
ft = [];

ct=x(1);
d=x(2);
dct = ct*d;

coef_mat = [ct,ct,ct,ct;dct,-dct,dct,-dct;-dct,dct,dct,-dct];
ft = (coef_mat*omega);

function use_LS_values(fitted_coefs,omega,T)
FT_true = T;
T_fit = [];
ct = fitted_coefs(1);
d = fitted_coefs(2);
dct = ct * d;
coef_mat = [ct,ct,ct,ct;dct,-dct,dct,-dct;-dct,dct,dct,-dct];

for i = 1:length(omega)
    T_fit = [T_fit,(coef_mat * omega(:,i))];
end

len = 1:length(omega);
figure('Visible','on')
plot(len,T_fit(1,:),'r:',len,T_fit(2,:),'k:',len,T_fit(3,:),'g:',len,FT_true(1,:),'r',len,FT_true(2,:),'k',len,FT_true(3,:),'g')

function plot_coef_vs_fitted(coef,fitted_coefs)
ct = coef(1,:);
d = coef(2,:)./coef(1,:);
len = 1:length(fitted_coefs(1,:));
figure('Visible','on')
plot(len,fitted_coefs(1,:),'r:+',len,fitted_coefs(2,:),'k:+',len,ct,'r',len,d,'k')
legend('LS Ct','LS d','Calculated Ct','Calculated d')

function ct_vs_omega(omega,coef,n1,n2)
len_coef = length(coef);
ave_omega_array = zeros(4,len_coef);
ave_omega = zeros(1,len_coef);
for i = 1:len_coef
    ave_omega_array(1,i) = mean(omega(1,n1(i):n2(i)));
    ave_omega_array(2,i) = mean(omega(2,n1(i):n2(i)));
    ave_omega_array(3,i) = mean(omega(3,n1(i):n2(i)));
    ave_omega_array(4,i) = mean(omega(4,n1(i):n2(i)));
end

for j = 1:len_coef
    ave_omega(j) = mean(ave_omega_array(:,j));
end

figure('Visible','on')
%plot(ave_omega,coef(1,:))
xlabel('Omega')
ylabel('ct')


%ct = beta*log(x-gamma);
%x(1) = beta;
%x(2) = gamma;

x0 = [.000006,1000];
fun = @(x,data) x(1)*log(data-x(2));
fit = lsqcurvefit(fun,x0,ave_omega,coef(1,:));
fprintf('beta = %e\ngamma = %e\n',fit(1),fit(2))

x1 = [.000006,1000,2];
fun2 = @(x,data) x(1)./(1+(1./(data-x(2)).^x(3)));
fit2 = lsqcurvefit(fun2,x1,ave_omega,coef(1,:));
fprintf('beta = %e\ngamma = %e\npower = %e\n',fit2(1),fit2(2),fit2(3))

plot(ave_omega,coef(1,:),ave_omega,fit(1)*log(ave_omega-fit(2)),ave_omega,fit2(1)./(1+(1./(ave_omega-fit2(2)).^fit2(3))),ave_omega,(2.089*10^-13).*ave_omega.^2.179,ave_omega,(2.2233514*10^-6)./(1+10245.12196*exp(-.0072175656.*ave_omega)))
legend('cT','log Fitted cT','exponential Fitted','Power Fit','Log Fit')







% for i = 1:length(omega)
%     ft = [ft,(coef_mat*omega(:,i))];
% end

