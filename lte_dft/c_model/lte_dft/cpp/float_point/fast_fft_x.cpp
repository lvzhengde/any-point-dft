//Radix 2^2 DIF pipeline FFT Processor float-point C-Model source code
//divide the calculation into ldn >> 1 + (ldn & 1) stages, ldn >> 1 are Radix-2^2 based algorithm
//(ldn & 1) is the last Radix-2 based algorithm
//the memory for each radix-2^2 stage are 3*(1 << ldn)/(4*4^stage_num)
//the memory can be implemented as 2 dual port SRAM, so can be accessed in parallel to speed up

#include "fast_fft_x.h"

#define  MAX_ADDR_BITS    (12)
#define  FFT_LDN          (12)

static const unsigned long RX = 4;
static const unsigned long LX = 2;

//decimation in frequency radix-2^2 FFT main body
//pipelined implementation
//non-optimized learners version
void fast_fft_x(complex<double> *f, unsigned long ldn, int is, bool bit_rev)
{
    complex<double> *data;
    unsigned long data_ldn;
    const unsigned long N_FFT = (1UL<<ldn);

    //decompose computation of FFT into pipeline stages
    for (unsigned long ldm=ldn; ldm>=LX; ldm-=LX)
    {
      unsigned long m = (1UL<<ldm);
      unsigned long i = 0;
      for (unsigned long j = 0; j < (1UL << ldn); j=j+(1UL << ldm))
      {
        unsigned long init_addr = i * m;
        data = &f[init_addr];
        data_ldn = ldm;
        radix4_stage_x(data, data_ldn, is);
        i = i + 1;
      }
    }
    
    if ( (ldn&1)!=0 )  // n is not a power of 4, need a radix-2 step
    {
        for (unsigned long r=0; r<N_FFT; r+=2)
        {
            complex<double> a0 = f[r];
            complex<double> a1 = f[r+1];
    
            f[r]   = a0 + a1;
            f[r+1] = a0 - a1;
        }
    }

    // bit reverse for output address
    if (bit_rev == true)
      revbin_permute_x(f, ldn);
}

//algorithm of one pipeline stage for Radix-2^2 decimation in frequency 
void radix4_stage_x(complex<double> *data, unsigned long data_ldn, int is)
{
    double m_pi = 4*atan(1.0);
    double s2pi = ( is>0 ? 2.0*m_pi : -2.0*m_pi );  
    const unsigned long N = (1UL << data_ldn);
    const unsigned long N_DIV_4 = N >> 2;
    const unsigned long N_DIV_2 = N >> 1;
    
    double ph0 = s2pi / N;
    
    complex<double> a0;
    complex<double> a1;
    complex<double> t0;
    complex<double> t1;  
    
    //loop variables
    unsigned long i;
    unsigned long k1;
    unsigned long k2;
    unsigned long n3;
    
    //calculate the first stage radix-2 butterfly
    for (i = 0; i < N_DIV_2; i++)
    {
      a0 = data[i];
      a1 = data[i+N_DIV_2];
      t0 = a0 + a1;
      t1 = a0 - a1;
      
      data[i] = t0;
      data[i+N_DIV_2] = t1;
    }
    
    //calculate the second stage radix-2 butterfly
    for (k1 = 0; k1 < 2; k1++)
    {
      for (i =0; i < N_DIV_4; i++)
      {
        if (k1 == 0)
        {
          a0 = data[i];
          a1 = data[i+N_DIV_4];
          t0 = a0 + a1;
          t1 = a0 - a1;
          data[i] = t0;        
          data[i+N_DIV_4] = t1;          
        }
        else
        {
          a0 = data[i+N_DIV_2];
          //swap real and imaginary part
          a1.real = data[i+N_DIV_2+N_DIV_4].imag;
          a1.imag = - data[i+N_DIV_2+N_DIV_4].real;
          t0 = a0 + a1;
          t1 = a0 - a1;
          data[i+N_DIV_2] = t0;        
          data[i+N_DIV_2+N_DIV_4] = t1;                    
        }
      }
    }
  
    //multiply by twiddle factors
    //results stored into output buffer
    for (k1 = 0; k1 < 2; k1++)
    {
      for (k2 = 0; k2 < 2; k2++)
      {
        for (n3 = 0; n3 < N_DIV_4; n3++)
        {
          double phi = n3*(k1+2*k2)*ph0;
          unsigned long addr = n3 + k1 * N_DIV_2 + k2 * N_DIV_4;
          complex<double> e(cos(phi), sin(phi));
          complex<double> t = data[addr];
          t *= e;
          data[addr] = t;
        }
      }
    }
}

// ordinary DIF radix-4 fft
// decimation in frequency radix-4 FFT main body
void fft_dif4l_x(complex<double> *f, unsigned long ldn, int is)
// Decimation in frequency (DIF) radix-4 FFT
// Non-optimized learners version
{
    double m_pi = 4*atan(1.0);
    double s2pi = ( is>0 ? 2.0*m_pi : -2.0*m_pi );

    const unsigned long n = (1UL<<ldn);
    for (unsigned long ldm=ldn; ldm>=LX; ldm-=LX)
    {
        unsigned long m = (1UL<<ldm);
        unsigned long m4 = (m>>LX);
        double ph0 = s2pi / m;

        for (unsigned long j=0; j<m4; j++)
        {
            double phi = j * ph0;
            complex<double> e(cos(phi), sin(phi));
            complex<double> e2(cos(2.0*phi), sin(2.0*phi));
            complex<double> e3(cos(3.0*phi), sin(3.0*phi));

            for (unsigned long r=0; r<n; r+=m)
            {
                unsigned long i0 = j + r;
                unsigned long i1 = i0 + m4;
                unsigned long i2 = i1 + m4;
                unsigned long i3 = i2 + m4;

                complex<double> a0 = f[i0];
                complex<double> a1 = f[i1];
                complex<double> a2 = f[i2];
                complex<double> a3 = f[i3];

                complex<double> t0 = (a0+a2) + (a1+a3);
                complex<double> t2 = (a0+a2) - (a1+a3);

                complex<double> t1 = (a0-a2) + complex<double>(0,is)*(a1-a3);
                complex<double> t3 = (a0-a2) - complex<double>(0,is)*(a1-a3);

                t1 *= e;
                t2 *= e2;
                t3 *= e3;

                f[i0] = t0;
                f[i1] = t2; // (!)
                f[i2] = t1; // (!)
                f[i3] = t3;
            }
        }
    }

    if ( (ldn&1)!=0 )  // n is not a power of 4, need a radix-2 step
    {
        for (unsigned long r=0; r<n; r+=2)
        {
            complex<double> a0 = f[r];
            complex<double> a1 = f[r+1];
    
            f[r]   = a0 + a1;
            f[r+1] = a0 - a1;
        }
    }
    
    // bit reverse for output address
    revbin_permute_x(f, ldn);
}

// bit reverse function
void revbin_permute_x(complex<double> *f, unsigned long ldn)
{
  //Writing out the normalized transform values in bit reversed order
  complex<double>            temp_result[1<<MAX_ADDR_BITS];
  unsigned long              i, j, n;
  unsigned long              reverse_index;

  n = (1UL<<ldn);
  
  //cout << "Writing the transform values..." << endl;
  for (i = 0; i < n; i++)
  {
     unsigned long x = i;
     reverse_index = 0;
     for(j = 0; j < ldn; j++)
     {
       reverse_index = reverse_index << 1; 
       reverse_index = reverse_index + (x&0x1); //parentheses is needed to clarify
       x = x >> 1;   
     }          
     temp_result[i] = f[reverse_index];
  }
   
  //re-store the result in array f
  for (i = 0; i < n; i++)
  {
    f[i] = temp_result[i];
  }
  //cout << "Done..." << endl;
}

