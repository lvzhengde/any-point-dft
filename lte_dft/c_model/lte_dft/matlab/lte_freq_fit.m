function y = lte_freq_fit(a, x)

mean_val = floor(length(x)/2); 
norm_const1 = 2^(floor(log2(length(x)))-1);
norm_const2 = 2^(floor(log2(length(x)))+1);

x1 = (x-mean_val)/norm_const1;
y1 = a(1)+a(2)*x1;%+a(3)*x1.*x1+a(4)*x1.*x1.*x1 ;
y2 = a(5)+a(6)*x1;

x2 = x/norm_const2;
y3 = (sinc(a(7)*x2).*sinc(a(7)*x2));

z = y1./y3;

y = y2 + z;
