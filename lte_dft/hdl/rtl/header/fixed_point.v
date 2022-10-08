`ifndef __FIXED_POINT_H__
`define __FIXED_POINT_H__

//symmetrical rounding and shift
`define SYMRND(x, y, cutbits) \
    if (cutbits <= 0) \
      y = x; \
    else \
      if (x >= 0) y = (x+$signed({1'b0,(1<<(cutbits-1))}))>>>cutbits; \
      else  y = (x+$signed({1'b0,(1<<(cutbits-1))-1}))>>>cutbits;

//symetrical saturation
`define SYMSAT(x, w) \
    if (x > (1 << (w-1)) - 1) \
      x = (1 << (w-1)) - 1; \
    else if (x < -(1 << (w-1)) + 1) \
      x = -(1 << (w-1)) + 1; \
    else \
      x = x;  

//symmetrical rounding and saturation
`define SYMRNDSAT(x, y, cutbits, w) \
    `SYMRND(x, y, cutbits); \
    `SYMSAT(y, w);
    
//data multiplication of fixed-point data
`define MULRNDSAT(x, y, z, qx, qy, qz, wz, temp, cutbits) \
    temp = x * y; \
    if (qz < (qx + qy)) begin \
      cutbits = qx + qy - qz; \
      `SYMRND(temp, z, cutbits); \
    end \
    else \
    	z = temp <<< (qz - qx - qy); \
  	SYMSAT(z, wz); \
  end

`endif  //__FIXED_POINT_H__