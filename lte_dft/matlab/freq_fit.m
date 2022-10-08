function y = freq_fit(a, x)

mean_val = mean(x);
std_val = std(x);

x1 = (x-mean_val)/256;
y1 = a(1)+a(2)*x1+a(6)*x1.*x1+a(7)*x1.*x1.*x1 ;
y3 = a(3)+a(4)*x1; %+a(7)*x1.*x1; 

x2 = x/1024;
y2 = (sinc(a(5)*x2).*sinc(a(5)*x2));

z = y1./y2;

y = y3 + z;

