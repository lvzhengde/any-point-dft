function [srcOut,srcMemory] = srcLinearUpSTx(srcIn,srcIn_plus,cnstdelta,os,lengthi,lut,srcMemory)

%   computes output signal of src

%   outputs:    
%   srcOut      the output data of src
%   enable      the output enable of src, it exist because src wl discard
%               point

%   inputs:     
%   srcIn       the input data of src

%   para:
%   pb          passband  default=4
%   srIn        input sample rate        default=25.3125
%   srOut       output sample rate       default=15.12
%   os          oversampling by polyphase interpolation filter   default=32
%   lut         lookup table with FIR coefficients    
%               for liear interpolation    size(lookup)=os*lengthi+1,and
%               the last is 0
%               default=6*32
%   lengthi     length of the interpolation filter  default=7 
%   bit_c       word length of coefficient interpolation 
%   bit_f       word length for FIR processing
%   bit_t       word length for time accumulator must be long




% here I use linear interpolator, so 2 datas is in need when a data is
% interpolated and out
% srcMemory is a structer   
% update the buffer
srcMemory.buffer=[srcIn,srcMemory.buffer(1:end-1)];
temp_buffer = [srcIn_plus,srcMemory.buffer(1:end-1)];
%%%%%%% initial output matrix, the output size is variable
srcOut=[];

%the statements at the bottom of this file should put here.
%corresponding to fixed C-model. However, initially, it located 
%at the bottom line.
%srcMemory.acc=srcMemory.acc-1;

%%%%%%%%%%%%%%% interpolation %%%%%%%%%%%%%%%%%%%%%
while srcMemory.acc<1
    % caculate the position of interpolation of coefficients
    ampAcc=os*srcMemory.acc; % it should be in [0,os)
    % to get the position of coefficient's interpolation
    posCoefInt=floor(ampAcc); % it should be [0,1,2,3,...os-1]
    % to get the timeshift(u) for coefficient's interpolation
    posCoefDec=ampAcc-floor(ampAcc);
    % linear interpolate for coefficients
    % linear:  h0(u)=u  (-1,0);   h1(u)=1-u  (0,1);
    h=[posCoefDec,1-posCoefDec];
    
    % interpolate the new coefficient based on the 
    % position message before
    
    for ii=1:lengthi
        % c(j)=lut((j-1)*os+posCoefInt+1)*h(2)+lut((j-1)*os+posCoefInt+1+1)*h(1);
        % c(j)=lut((j-1)*os+posCoefInt+1:(j-1)*os+posCoefInt+1+1)*h';
        % can save 1 multiplication
        if (posCoefInt < os-1)
            c(ii)=lut((ii-1)*os+posCoefInt+1)+(lut((ii-1)*os+posCoefInt+1+1)-lut((ii-1)*os+posCoefInt+1))*posCoefDec;
        else  %deal with special case posCoefInt = os - 1
          if (ii < lengthi)
            c(ii)=lut((ii-1)*os+posCoefInt+1)+(lut((ii-1)*os+posCoefInt+1+1)-lut((ii-1)*os+posCoefInt+1))*posCoefDec;
          else
            c(ii)=lut((ii-1)*os+posCoefInt+1)+(lut(1)-lut((ii-1)*os+posCoefInt+1))*posCoefDec;
          end
        end
    end
    % c=lut(posCoefInt+1:os:end)*h1+lut(posCoefInt+1+1:os:end)*h0
        
    % convolute the new coefs and the data in buffer
    tmp=srcMemory.buffer*c';
    if (posCoefInt < os-1)
      delta_out = 0;
    else  %modify result
      delta_out = (srcIn_plus - srcMemory.buffer(end))*posCoefDec*lut(1);
    end
    tmp = tmp + delta_out;
    srcOut=[srcOut,tmp];
    
    %%original code for src output
%     if (posCoefInt < os-1)
%       tmp=srcMemory.buffer*c';
%       srcOut=[srcOut,tmp];
%     else
%       for ii = 1:lengthi
%         c_1(ii) = lut((ii-1)*os+posCoefInt+1);
%         c_2(ii) = lut((ii-1)*os+1);
%       end
%       tmp_1 = srcMemory.buffer*c_1';
%       tmp_2 = temp_buffer*c_2';
%       tmp = tmp_1 + (tmp_2 - tmp_1)*posCoefDec;
%       %for test purpose
%       %tmp = tmp_1*sinc(1-posCoefDec) + tmp_2*sinc(posCoefDec);
%       srcOut=[srcOut,tmp];
%     end
    
    % update acc for current srcIn
    srcMemory.acc=srcMemory.acc+cnstdelta;
end

%%%%%%%%%% prepare for the next input data to interpolation %%%%%%%%%%%%%%
%the positon of the following statements should change to the beginning of 
%this file to coincide with fixed C-model.
srcMemory.acc=srcMemory.acc-1;

    




