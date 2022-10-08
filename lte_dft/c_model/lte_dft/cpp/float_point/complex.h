#ifndef _COMPLEX_H_
#define _COMPLEX_H_

template <class T>
class complex {
public:
    T real;
    T imag;
    complex(T r=0, T i=0)
    {
      real = r;
      imag = i;
    }
    ~complex()
    {
    }
    
    template <class T1>
    complex<T>& operator=   (const complex<T1> &c)
    {
        real = (T)c.real;
        imag = (T)c.imag;
        return *this;
    }    
    complex<T>& operator=   (const T d)
    {
        real = d;
        imag = 0;
        return *this;
    }
    template <class T1>
    complex<T>& operator+=  (const complex<T1> &c)
    {
        real += (T)c.real;
        imag += (T)c.imag;
        return *this;
    }    
    template <class T1>
    complex<T>& operator-=  (const complex<T1> &c)
    {
        real -= (T)c.real;
        imag -= (T)c.imag;
        return *this;
    }    
    template <class T1>
    complex<T>& operator*=  (const complex<T1> &c)
    {
        double R = (real*c.real) - (imag*c.imag);
        double I = (imag*c.real) + (real*c.imag);
    
        real = R;
        imag = I;
    
        return *this;
    }    
    complex<T>& operator*=  (const T scalar)
    {
        real *= scalar;
        imag *= scalar;
        return *this;
    }    
    template <class T1>
    complex<T>& operator/=  (const complex<T1> &c)
    {
        double denom  = (c.real*c.real) + (c.imag*c.imag);
        double R = ((real*c.real) + (imag*c.imag))/denom;
        double I = ((imag*c.real) - (real*c.imag))/denom;
        real = R;
        imag = I;
        return *this;
    }   
    complex<T>& operator/=  (const T scalar)
    {
        real /= scalar;
        imag /= scalar;
        return *this;
    }    
    template <class T1>
    complex<T>  operator+   (const complex<T1> &c)
    {
        complex<T> result = *this;
    
        result += c;
        return result;
    }    
    template <class T1>
    complex<T>  operator-   (const complex<T1> &c)
    {
        complex<T> result = *this;
    
        result -= c;
        return result;
    }    
    template <class T1>
    complex<T>  operator*   (const complex<T1> &c)
    {
        complex<T> result = *this;
    
        result *= c;
        return result;
    }    
    complex<T>  operator*   (const T scalar)
    {
        complex<T> result = *this;
    
        result *= scalar;
        return result;
    }    
    template <class T1>
    complex<T>  operator/   (const complex<T1> &c)
    {
        complex<T> result = *this;
    
        result /= c;
        return result;
    }   
    complex<T>  operator/   (const T);
    int      operator==  (const complex&);
    int      operator!=  (const complex&);
};

// function definition
template <class T>
complex<T> complex<T>::operator/ (const T scalar)
{
    complex<T> result = *this;

    result /= scalar;
    return result;
}

template <class T>
int complex<T>::operator== (const complex<T> &c)
{
    return ((real == c.real) && (imag == c.imag));
}

template <class T>
int complex<T>::operator!= (const complex<T> &c)
{
    return ((real != c.real) || (imag != c.imag));
}

// unary operators
template <class T>
complex<T> conj(const complex<T> &c)
{
	complex<T> R;

	R.real =  c.real;
	R.imag = -c.imag;
	return R;
}

template <class T>
complex<T> operator- (const complex<T> &c)
{
	complex<T> R;

	R.real = -c.real;
	R.imag = -c.imag;
	return R;
}

template <class T>
T real(const complex<T> &c)
{
	return c.real;
}

template <class T>
T imag(const complex<T> &c)
{
	return c.imag;
}

template <class T>
double abs(const complex<T> &c)
{
  double real;
  double imag;
  real = (double)c.real;
  imag = (double)c.imag;
  
	return sqrt(real * real + imag * imag);
}

template <class T>
double ang(const complex<T> &c)
{
  double real;
  double imag;
  real = (double)c.real;
  imag = (double)c.imag;
  
	return atan2(imag , real);
}


#endif // _COMPLEX_H_ 
