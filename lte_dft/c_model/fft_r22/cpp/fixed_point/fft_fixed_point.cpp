/*++
  File Name:   fft_fixed_point.cpp
  Description: implemntation of common functions for fixed point operation
--*/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "fft_fixed_point.h"

#define  MAX_WIDTH    (32)

//#define CLIP_SATURATION

int float2fixed(double x, int q) 
{
/*++
  Description: conversion from float point to fixed point
  Parameters:
    x: input float point
    q: fractional point position, q=0 is integer
  Global variables:
    None
  Return value:
    converted fixed point number
--*/
  int temp;

  temp = (int)(x * (1 << q));
  return temp;
}

double fixed2float(int x, int q) 
{
/*++
  Description: conversion from fixed point to float point
  Parameters:
    x: input fixed point number
    q: fractional point position, q=0 is integer in fact
  Global variables:
    None
  Return value:
    converted float point number
--*/
  double temp, divisor;

  divisor = 1 << q;
  temp = (float)(x / divisor);
  return temp;
}


int fixed_add(int x, int y, int qx, int qy, int qz, int wz) 
{
/*++
  Description: fixed point addition z = x + y
  Parameters:
    x, y: operands of adder
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x + y
--*/

  int temp, z;
  
  if (qx >= qy) {
    temp = y << (qx - qy);
    temp = x + temp;
    if(qx >= qz)
      z = (int)(temp >> (qx - qz));
    else
      z = (int)(temp << (qz - qx));
    }
  else {
  	temp = x << (qy - qx);
  	temp = temp + y;
  	if (qy >= qz)
  		z = (int)(temp >> (qy - qz));
  	else
  		z = (int)(temp << (qz - qy));
  	}
  	
  if (abs(z) > (1 << (wz -1)) - 1)
    printf("Overflow occurred in fixed add operation! \n");   	
  	
#ifdef CLIP_SATURATION
  //symmetrical saturation
	if (z > (1 << (wz -1)) - 1)
	{
	  z = (1 << (wz -1)) - 1;
	}
	if (z < -((1 << (wz -1)) - 1))
	{
	  z = -((1 << (wz -1)) - 1);
	}
#endif   	 
  	 
  return z;
}

int fixed_sub(int x, int y, int qx, int qy, int qz, int wz) 
{
/*++
  Description: fixed point subtraction z = x - y
  Parameters:
    x, y: operands of subtracter
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x - y
--*/

  int temp, z;
  
  if (qx >= qy) {
    temp = y << (qx - qy);
    temp = x - temp;
    if(qx >= qz)
      z = (int)(temp >> (qx - qz));
    else
      z = (int)(temp << (qz - qx));
    }
  else {
  	temp = x << (qy - qx);
  	temp = temp - y;
  	if (qy >= qz)
  		z = (int)(temp >> (qy - qz));
  	else
  		z = (int)(temp << (qz - qy));
  	}
  	
  if (abs(z) > (1 << (wz -1)) - 1)
    printf("Overflow occurred in fixed sub operation! \n");  
       	
#ifdef CLIP_SATURATION
  //symmetrical saturation
	if (z > (1 << (wz -1)) - 1)
	{
	  z = (1 << (wz -1)) - 1;
	}
	if (z < -((1 << (wz -1)) - 1))
	{
	  z = -((1 << (wz -1)) - 1);
	}
#endif   	 
  	 
  return z;
}

int fixed_mul(int x, int y, int qx, int qy, int qz, int wz) 
{
/*++
  Description: fixed point multiplication z = x * y
  Parameters:
    x, y: operands of multiplier
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x * y
--*/

  int temp, z;
  
  temp = x * y;
  if (qz < (qx + qy))
  	z = temp >> (qx + qy - qz);
  else
  	z = temp << (qz - qx - qy);

  if (abs(z) > (1 << (wz -1)) - 1)
    printf("Overflow occurred in fixed mul operation! \n");   
    
#ifdef CLIP_SATURATION
  //symmetrical saturation
	if (z > (1 << (wz -1)) - 1)
	{
	  z = (1 << (wz -1)) - 1;
	}
	if (z < -((1 << (wz -1)) - 1))
	{
	  z = -((1 << (wz -1)) - 1);
	}
#endif   	 
  	 
  return z;
}

int fixed_div(int x, int y, int qx, int qy, int qz, int wz) 
{
/*++
  Description: fixed point division z = x / y
  Parameters:
    x, y: operands of divisor
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x / y
--*/

  int temp, z;
  
  temp = x;
 
  if (qz < (qx - qy)) 
  	z = (temp >> (qx - qy - qz)) / y;
  else 
  	z = (temp << (qz - qx + qy)) / y;

  if (abs(z) > (1 << (wz -1)) - 1)
    printf("Overflow occurred in fixed div operation! \n");   

#ifdef CLIP_SATURATION
  //symmetrical saturation
	if (z > (1 << (wz -1)) - 1)
	{
	  z = (1 << (wz -1)) - 1;
	}
	if (z < -((1 << (wz -1)) - 1))
	{
	  z = -((1 << (wz -1)) - 1);
	}
#endif   	 
  	   	 
  return z;
  
}

// just truncate the result
int TruncateShift(int in, int CutBits) 
{
int out;

    out = in>>CutBits;
    
    return out;
}

//fixed point type conversion without rounding
//just clip it and saturation
int signed_fixed2fixed(int x, int qx, int qy, int wy)
{
  int        output;
  int        cutbits;
  
  if (qy < qx)
    cutbits = qx - qy;
  else
    cutbits = qy - qx;
  
  if (qy < qx)
    output = x >> cutbits;
  else
    output = x << cutbits;

#ifdef CLIP_SATURATION  
	//symmetrical saturation
	if (output > (1 << (wy -1)) - 1)
	{
	  output = (1 << (wy -1)) - 1;
	}
	if (output < -((1 << (wy -1)) - 1))
	{
	  output = -((1 << (wy -1)) - 1);
	}
#endif
	
	return output;
}

//fixed-point operation with saturation and round
int float2fixed_satrnd(double x, int q, int w)
{
/*++
  Description: 
    conversion from float point to fixed point
    with round and saturation
  Parameters:
    x: input float point
    q: fractional point position, q=0 is integer
    w: bit-width of fixed point data
  Global variables:
    None
  Return value:
    converted fixed point number
--*/
  int        output;
  double     flt_output;
  
  flt_output = x * pow(2.,q); 
  
	//symmetrical quantization
	if (flt_output >= 0)
	{
	  flt_output = floor(flt_output + 0.5);
	}
	else
	{
	  flt_output = ceil(flt_output - 0.5);
	}

	//symmetrical saturation
	output = (int)flt_output;
	
	if (output > (1 << (w -1)) - 1)
	{
	  output = (1 << (w -1)) - 1;
	}
	if (output < -((1 << (w -1)) - 1))
	{
	  output = -((1 << (w -1)) - 1);
	}
	
	return output;
}

int fixed_add_satrnd(int x, int y, int qx, int qy, int qz, int wz)
{
/*++
  Description: 
    fixed point addition z = x + y
    with round and saturation
  Parameters:
    x, y: operands of adder
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x + y
--*/

  int temp, z;
  int cutbits;
  
  if (qx >= qy) 
  {
    temp = y << (qx - qy);
    temp = x + temp;
    //round it
    if(qx > qz)
    {
      cutbits = qx - qz;
      if (temp >= 0)
      {
        z = (temp + (1 << (cutbits-1))) >> cutbits;
      }
      else
      {
        //z = -((-temp + (1 << (cutbits-1))) >> cutbits); 
        z = (temp+(1<<(cutbits-1))-1)>>cutbits; 
      }
    }
    else
      //no round needed
      z = (int)(temp << (qz - qx));
  }
  else 
  {
  	temp = x << (qy - qx);
  	temp = temp + y;
  	//round it
  	if (qy > qz)
  	{
  	  cutbits = qy-qz;
  	  if (temp >= 0)
  	  {
  		  z = (temp + (1 << (cutbits-1)))>> cutbits;
  	  }
  	  else
  	  {
        //z = -((-temp + (1 << (cutbits-1))) >> cutbits); 
        z = (temp+(1<<(cutbits-1))-1)>>cutbits; 
  	  } 	  
  	}
  	else
  	  //no round needed
  		z = (int)(temp << (qz - qy));
  }
  
  //symmetrical saturation
	if (z > (1 << (wz -1)) - 1)
	{
	  z = (1 << (wz -1)) - 1;
	}
	if (z < -((1 << (wz -1)) - 1))
	{
	  z = -((1 << (wz -1)) - 1);
	}
   	 
  return z;
}

int fixed_sub_satrnd(int x, int y, int qx, int qy, int qz, int wz)
{
/*++
  Description: 
    fixed point subtraction z = x - y
    with round and saturation
  Parameters:
    x, y: operands of subtracter
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x - y
--*/

  int temp, z;
  int cutbits;
  
  if (qx >= qy) 
  {
    temp = y << (qx - qy);
    temp = x - temp;
    //round it
    if(qx > qz)
    {
      cutbits = qx - qz;
      if (temp >= 0)
      {
        z = (temp + (1 << (cutbits-1))) >> cutbits;
      }
      else
      {
        //z = -((-temp + (1 << (cutbits-1))) >> cutbits); 
        z = (temp+(1<<(cutbits-1))-1)>>cutbits; 
      }
    }
    else
      //no round needed
      z = (int)(temp << (qz - qx));
  }
  else 
  {
  	temp = x << (qy - qx);
  	temp = temp - y;
  	//round it
  	if (qy > qz)
  	{
  	  cutbits = qy - qz;
  	  if (temp >= 0)
  	  {
  		  z = (temp + (1 << (cutbits-1)))>> cutbits;
  	  }
  	  else
  	  {
        //z = -((-temp + (1 << (cutbits-1))) >> cutbits); 
        z = (temp+(1<<(cutbits-1))-1)>>cutbits; 
  	  } 	  
  	}
  	else
  	  //no round needed
  		z = (int)(temp << (qz - qy));
  }

  //symmetrical saturation
	if (z > (1 << (wz -1)) - 1)
	{
	  z = (1 << (wz -1)) - 1;
	}
	if (z < -((1 << (wz -1)) - 1))
	{
	  z = -((1 << (wz -1)) - 1);
	}
	  	 
  return z;
}

int fixed_mul_satrnd(int x, int y, int qx, int qy, int qz, int wz)
{
/*++
  Description: 
    fixed point multiplication z = x * y
    with round and shift
  Parameters:
    x, y: operands of multiplier
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x * y
--*/

  int temp, z;
  int cutbits;
  
  temp = x * y;
  if (qz < (qx + qy))
  // round it
  {
    cutbits = qx + qy - qz;
    if (temp >= 0)
    {
      z = (temp + (1 << (cutbits-1))) >> cutbits;
    }
    else
    {
      //z = -((-temp + (1 << (cutbits-1))) >> cutbits);  
      z = (temp+(1<<(cutbits-1))-1)>>cutbits;
    }    
  }
  else
  // no round needed
  	z = temp << (qz - qx - qy);

  //symmetrical saturation
	if (z > (1 << (wz -1)) - 1)
	{
	  z = (1 << (wz -1)) - 1;
	}
	if (z < -((1 << (wz -1)) - 1))
	{
	  z = -((1 << (wz -1)) - 1);
	}
  	 
  return z;
}

int fixed_div_satrnd(int x, int y, int qx, int qy, int qz, int wz)
{
/*++
  Description: 
    fixed point division z = x / y
    with round and shift
  Parameters:
    x, y: operands of divisor
    qx, qy, qz: fractional point position of x, y, z
  Global variables:
    None
  Return value:
    z, the result of x / y
--*/

  double  flt_x, flt_y, flt_z;  
  int     z;
  
  flt_x = x * pow(2., -qx); 
  flt_y = y * pow(2., -qy);
  flt_z = flt_x/flt_y;
  
  z = float2fixed_satrnd(flt_z, qz, wz);
  	 
  return z;
}

//fixed point type conversion
int signed_fixed2fixed_satrnd(int x, int qx, int qy, int wy)
{
  int        output;
  int        cutbits;
  
  if (qy < qx)
    cutbits = qx - qy;
  else
    cutbits = qy - qx;
  
  if (qy < qx)
  //round it
  {
    if (x >= 0)
    {
      output = (x + (1 << (cutbits-1))) >> cutbits;
    }
    else
    {
      output = (x + (1 << (cutbits-1))-1) >> cutbits;
    }
  }
  else
    //no round needed
    output = x << cutbits;
  
	//symmetrical saturation
	if (output > (1 << (wy -1)) - 1)
	{
	  output = (1 << (wy -1)) - 1;
	}
	if (output < -((1 << (wy -1)) - 1))
	{
	  output = -((1 << (wy -1)) - 1);
	}
	
	return output;
}

//shift operation, used for dividing 2^n operation
int SymRoundShift(int in, int CutBits) 
{
    int out;

    if (CutBits <= 0)
      out = in;
    else {
      if (in >= 0)    out = (in+(1<<(CutBits-1)))>>CutBits;
      else            out = (in+(1<<(CutBits-1))-1)>>CutBits;
    }
   
    return out;
}

//saturation
int sym_saturation(int in, int data_width)
{
  int abs_max_value = (1 << (data_width-1)) - 1;
  int out;
  
  if (in > abs_max_value)
    out = abs_max_value;
  else if (in < -abs_max_value)
    out = -abs_max_value;
  else
    out = in;
  
  return out;
}

//barrel shift count
int barrel_shift(int max_value, int man_width_m)
{
  //sc_uint<MAX_WIDTH>  bits_index = max_value;
  int bits_index = max_value;
  int shift_count = 0;
  for (int i = man_width_m-2; i >= 0; i--)
  {
    //if (bits_index[i] == 1)
    if ((bits_index&(1<<i)) == 1) 
      break;
    shift_count = shift_count + 1;
  }
  
  return shift_count;
}

//fixed point to hybrid float point conversion
void fixed2bfp(int &data_real, int &data_imag, int &data_exp, int in_ptpos, int in_width, int out_manwidth, int out_expwidth)
/*
  data_real: input and output
  data_imag: input and output
  data_exp: output only
  in_ptpos: input only
  in_width: input only
  out_width: input only
  out_expwidth: input only
*/
{
  //hybrid float point, determine the exponent and mantissa
  int abs_data_real;
  int abs_data_imag;
  int abs_max_value;
  
  if (data_real >= 0)
    abs_data_real = data_real;
  else
    abs_data_real = -data_real;
  
  if (data_imag >= 0)
    abs_data_imag = data_imag;
  else
    abs_data_imag = -data_imag;
  
  if (abs_data_real >= abs_data_imag)
    abs_max_value = abs_data_real;
  else
    abs_max_value = abs_data_imag;
  
  //emulate barrel shift
  //sc_uint<MAX_WIDTH>  bits_index = abs_max_value;
  int bits_index = abs_max_value;
  int lshift_count = 0;
  for (int i = in_width-2; i >= 0; i--)
  {
    //if (bits_index[i] == 1) 
    //if ((bits_index&(1<<i)) == 1)
    if(((bits_index>>i) & 0x1) == 1)
      break;
    lshift_count = lshift_count + 1;
  }
  
  int exponent = in_width - 1 - in_ptpos - lshift_count;
  data_real = data_real << lshift_count;
  data_imag = data_imag << lshift_count;
  
  int cutbits = in_width - out_manwidth;
  if (cutbits >= 0)
  {
    //round real part
    if(data_real >= 0)
      data_real = (data_real + (1 << (cutbits-1))) >> cutbits;
    else
      data_real = (data_real +  (1 << (cutbits-1)) -1) >> cutbits;
    //round imaginary part
    if(data_imag >= 0)
      data_imag = (data_imag + (1 << (cutbits-1))) >> cutbits;
    else
      data_imag = (data_imag +  (1 << (cutbits-1)) -1) >> cutbits;        
  }
  else
  {
    data_real = data_real << (-cutbits);
    data_imag = data_real << (-cutbits);
  }      
  
  data_exp = exponent;
}

//hybrid float-point to fixed-point data conversion
void bfp2fixed(int &data_real, int &data_imag, int data_exp, int in_manwidth, int out_ptpos, int out_width)
/*
  data_real: input and output
  data_imag: input and output
  data_exp:  input only
  in_manwidth:  input only
  out_ptpos:  input only
  out_width: input only
*/

{
  int shift_count = out_ptpos + data_exp - (in_manwidth - 1);
  if (shift_count >=0)   //left shift
  {
    data_real = data_real << shift_count;
    data_imag = data_imag << shift_count;

    //symmetrical saturation
    if (data_real > (1 << (out_width-1))-1)
      data_real = (1 << (out_width-1))-1;
    if (data_real < -((1 << (out_width-1))-1))
      data_real = -((1 << (out_width-1))-1);
    if (data_imag > (1 << (out_width-1))-1)
      data_imag = (1 << (out_width-1))-1;
    if (data_imag < -((1 << (out_width-1))-1))
      data_imag = -((1 << (out_width-1))-1);  
  }
  else    //right shift with round
  {
    int cutbits = -shift_count;
  	if (data_real >= 0)
  	  data_real = (data_real + (1 << (cutbits-1)))>> cutbits;
  	else
      data_real = (data_real+(1<<(cutbits-1))-1)>>cutbits;  	
  	if (data_imag >= 0)
  	  data_imag = (data_imag + (1 << (cutbits-1)))>> cutbits;
  	else
      data_imag = (data_imag+(1<<(cutbits-1))-1)>>cutbits;  	  
  }
}

void bfp2float(int data_real_in, int data_imag_in, int data_exp_in, int in_manwidth, double &data_real_out, double &data_imag_out)
/*
  input parameters:
    data_real in
    data_imag_in
    data_exp_in
    in_manwidth
  output parameters:
    data_real_out
    data_imag_out
*/
{ 
  data_real_out = ((double)data_real_in) * pow(2.0, -(in_manwidth-1)) * pow(2.0, data_exp_in);
  data_imag_out = ((double)data_imag_in) * pow(2.0, -(in_manwidth-1)) * pow(2.0, data_exp_in);
}
