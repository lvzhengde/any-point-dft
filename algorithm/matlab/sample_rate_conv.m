function [src_out,src_memory] = sample_rate_conv(src_in,src_in_plus,cnst_delta,os,lengthi,lut,src_memory)

%   sample rate conversion of input data
%   parameters
%   outputs:    
%   src_out      output of sample rate conversion


%   inputs:     
%   src_in       input data of delay line
%   src_in_plus  the next input data of delay line
%   lengthi      length of the polyphase filter

% update the buffer
src_memory.buffer=[src_in,src_memory.buffer(1:end-1)];

src_out=[];

src_memory.acc=src_memory.acc-1;

%interpolation operation
while src_memory.acc<1 
    amp_acc=os*src_memory.acc;   %  in [0,os)
    pos_coef_int=floor(amp_acc); %  in [0,1,2,3,...os-1]
    pos_coef_dec=amp_acc-floor(amp_acc);

    % interpolate the new coefficient based on the 
    % position message before
    for ii=1:lengthi
        if (pos_coef_int < os-1)
            c1(ii) = lut((ii-1)*os+pos_coef_int+1);
            c2(ii) = lut((ii-1)*os+pos_coef_int+1+1);
            c(ii)=lut((ii-1)*os+pos_coef_int+1)+(lut((ii-1)*os+pos_coef_int+1+1)-lut((ii-1)*os+pos_coef_int+1))*pos_coef_dec;
        else  %deal with special case pos_coef_int = os - 1
          if (ii < lengthi)
            c1(ii) = lut((ii-1)*os+pos_coef_int+1);
            c2(ii) = lut((ii-1)*os+pos_coef_int+1+1);           
            c(ii)=lut((ii-1)*os+pos_coef_int+1)+(lut((ii-1)*os+pos_coef_int+1+1)-lut((ii-1)*os+pos_coef_int+1))*pos_coef_dec;
          else
            c1(ii) = lut((ii-1)*os+pos_coef_int+1);
            c2(ii) = lut(1);                       
            c(ii)=lut((ii-1)*os+pos_coef_int+1)+(lut(1)-lut((ii-1)*os+pos_coef_int+1))*pos_coef_dec;
          end
        end
    end
        
    % convolute the new coefs and the data in buffer
    tmp=src_memory.buffer*c';
    if (pos_coef_int < os-1)
      delta_out = 0;
    else  %modify result
      delta_out = (src_in_plus - src_memory.buffer(end))*pos_coef_dec*lut(1);
    end
    tmp = tmp + delta_out;
    src_out=[src_out,tmp];
    
    % update acc for current srcIn
    src_memory.acc=src_memory.acc+cnst_delta;
end





