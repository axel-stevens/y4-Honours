//interface#=usbsetinterface1;
// return 1, else error

#include <stdio.h>
#include "C:\Program Files\MATLAB\R2010b\extern\include\mex.h"
#include <windows.h>
#include <malloc.h>
#include "C:\Cypress\Cypress Suite USB 3.4.7\CyAPI\inc\CyAPI.h"


void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
  
{
	CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL); 
	USBDevice->SetAltIntfc(1); 
	int	altintfc=USBDevice->AltIntfc();
	plhs[0] = mxCreateDoubleMatrix(1,1, mxREAL);
	double *y;
	y = mxGetPr(plhs[0]);
	*y=altintfc;
	delete USBDevice;
	return;
}
