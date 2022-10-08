function Y = cooley_tukey(x, N, N1, N2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Cooley-Tukey FFT
%x: input complex data
%N: data length, N = N1*N2
%Y: output FFT result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%do row fft
for n2 = 0:1:(N2-1)
    for n1 = 0:1:(N1-1)
        x1(n1+1) = x(N2*n1 + n2 + 1);
    end
    Y1 = fft(x1, N1);
    
    %multiply with twiddle factor
    Y1 = Y1.*exp(-j*2*pi*n2*[0:1:(N1-1)]/N);
    
    %store row fft result in place
    for n1 = 0:1:(N1-1)
       x(N2*n1 + n2 + 1) = Y1(n1 + 1); 
    end
end

%do column fft
for n1 = 0:1:(N1-1)
    for n2 = 0:1:(N2-1)
        x2(n2 + 1) = x(N2*n1 + n2 + 1);
    end
    
    Y2 = fft(x2, N2);
    
    %store column fft result in place
    for n2 = 0:1:(N2-1)
        x(N2*n1 + n2 + 1) = Y2(n2 + 1);
    end
end

%output fft result
for k1 = 0:1:(N1-1)
    for k2 = 0:1:(N2-1)
        Y(k1 + N1*k2 + 1) = x(N2*k1 + k2 + 1);
    end
end


