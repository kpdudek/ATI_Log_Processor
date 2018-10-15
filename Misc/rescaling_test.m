function rescaling_test
load('POCidentification_all_coefs_2018_06_06_Circles_Acro.mat')
load('POCidentification_test_span_2018_06_06_Circles_Acro.mat')

ave_omega = prep_omegas(coef,omega,n1,n2);
ct = coef(1,:);

x3 = [(2.089*10^-6),10245,.007217];
fun4 = @(x,data) x(1)./(1+x(2).*exp(-x(3).*data));
fit4 = nlinfit(ave_omega,coef(1,:),fun4,x3);
fprintf('beta = %e\ngamma = %e\npower = %e\n',fit4(1),fit4(2),fit4(3))
ct3 = fit4(1)./(1+fit4(2)*exp(-fit4(3).*ave_omega));

x = [(2.089*10^-6),10245,.007217];
fun = @(x,data) x(1)./(1+x(2).*exp(-x(3).*data));
fit = nlinfit(ave_omega.*10000,coef(1,:).*10000,fun,x.*10000);
fprintf('\nbeta = %e\ngamma = %e\npower = %e\n',fit(1),fit(2),fit(3))
fit = fit./10000;
ct0 = fit(1)./(1+fit(2)*exp(-fit(3).*ave_omega));

x1 = [(2.089*10^-6),10245,.007217];
fun2 = @(x,data) x(1)./(1+x(2).*exp(-x(3).*data));
fit2 = lsqcurvefit(fun2,x1,ave_omega,coef(1,:));
fprintf('beta = %e\ngamma = %e\npower = %e\n',fit2(1),fit2(2),fit2(3))
ct2 = fit2(1)./(1+fit2(2).*exp(-fit2(3).*ave_omega));

figure('Visible','on')
plot(ave_omega,coef(1,:),ave_omega,ct3,ave_omega,ct0,ave_omega,ct2)
legend('CT','nlin','nlin','lsq')

mean_error(ct,ct0,'nlinfit')
mean_error(ct,ct2,'lsqcurvefit')


function ave_omega = prep_omegas(coef,omega,n1,n2)
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

function mean_error(ct,ct_estimated,string)
error = immse(ct,ct_estimated);
print = sprintf('The error for %s is %e\n',string,error);
fprintf('%s',print)










