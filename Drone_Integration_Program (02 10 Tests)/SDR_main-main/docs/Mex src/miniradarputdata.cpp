//[outlength]=miniradarputdata(buffer,endpoint2_no,);
//outlength:0, error. 1, ok.  length:0, error. else, actual data length


#include <stdio.h>
#include "C:\Program files\MATLAB\R2010b\extern\include\mex.h"
#include "C:\Program files\MATLAB\R2010b\extern\include\matrix.h"
#include <windows.h>
#include <winbase.h>
#include <malloc.h>
#include "C:\Cypress\Cypress Suite USB 3.4.7\CyAPI\inc\CyAPI.h"


void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs, mxArray *prhs[])
  
{  
    int endpoint2;

    UCHAR *data;
    LONG outlength=512;
    double *x, *y;
    x = mxGetPr(prhs[1]);
    endpoint2=int (*x);
    //mexPrintf("%d\n", endpoint2 );   
    //double *buf;
    data=(UCHAR *) mxGetPr(prhs[0]);
    mexPrintf( "%d\n", *data );  
    mexPrintf( "%d\n", *(data+1) );  
    mexPrintf( "%d\n", *(data+2) );  
    mexPrintf( "%d\n", *(data+3) );  
    plhs[0]=mxCreateDoubleMatrix(1,1, mxREAL);
    y=(double *) mxGetPr(plhs[0]); 
      
    CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL); 
    USBDevice->EndPoints[endpoint2]->XferData(data, outlength);       
	*y=outlength;
    if (*y==0)
		return;

	delete USBDevice;

	return;
}
