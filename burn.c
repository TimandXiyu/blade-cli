#include <stdlib.h>
#include <unistd.h>
#include <math.h>
int main(int c,char**v){int n=atoi(v[1]);for(int i=1;i<n;i++)if(fork()==0)break;
 volatile double x=0.0001; for(;;){ x+=1.0; x*=1.0000001; x=sqrt(x*x+1.0);} return 0;}
