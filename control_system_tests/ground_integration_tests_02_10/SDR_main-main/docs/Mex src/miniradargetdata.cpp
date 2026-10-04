//[data,outlength,length]=usbgetdata(endpoint1_no,endpoint6_no,length);
//outlength:0, error. 1, ok.  length:0, error. else, actual data length


#include <stdio.h>
#include "C:\MATLAB\R2010b\extern\include\mex.h"
#include "C:\MATLAB\R2010b\extern\include\matrix.h"
#include <windows.h>
#include <winbase.h>
#include <malloc.h>
#include "C:\Cypress\Cypress Suite USB 3.4.7\CyAPI\inc\CyAPI.h"


void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
  
{   double *x;

    LONG length;
    x = mxGetPr(prhs[1]);
    length=LONG (*x);
    int dim[2]={1,1};
    dim[1]=int (length);
    plhs[0]=mxCreateNumericArray(2,dim,mxUINT16_CLASS,mxREAL);
    
    //mexPrintf("%d\n",dim[1]);
    
	CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL); 
    dim[1]=1;
	plhs[1] = mxCreateNumericArray(2,dim,mxINT64_CLASS,mxREAL);
    LONG *y;
    int i,endpoint6;
    UCHAR *buf;
    y=(LONG *)mxGetPr(plhs[1]);
	x = mxGetPr(prhs[0]);
    endpoint6= int (*x);
    
    buf=(UCHAR *) mxGetPr(plhs[0]);
    
	USBDevice->EndPoints[endpoint6]->XferData(buf, length);    
	*y=length;
    if (*y==0)
		return;

	delete USBDevice;

	return;
}
