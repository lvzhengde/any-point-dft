polyphase_window = 3;

os= 32; 
polyphase= 2*polyphase_window;

%transition band
ibf=0.350;
n=os*polyphase-1;
f = [0 (1.0-ibf)/os (1.0+ibf)/os 1];
m=[1 1 0 0];
w=[1 1000000]; %[1 10000];
lutRx_2=os*remez(n,f,m,w);

%add window
ham = kaiser(os*polyphase,3.8);
lutRx_2 = lutRx_2 .* ham';