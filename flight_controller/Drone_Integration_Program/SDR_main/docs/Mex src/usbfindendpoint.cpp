//endpoint#=usbfindendpoint(endpointaddress);
//return 0 error


#include <stdio.h>
#include "C:\Program Files\MATLAB\R2010b\extern\include\mex.h"
#include <windows.h>
#include <malloc.h>
#include "C:\Cypress\Cypress Suite USB 3.4.7\CyAPI\inc\CyAPI.h"


void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
  
{
	CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL); 
	plhs[0] = mxCreateDoubleMatrix(1,1, mxREAL);
	double *x,*y;
	y = mxGetPr(plhs[0]);
	x = mxGetPr(prhs[0]);
	*y=0;
	int eptCount = USBDevice->EndPointCount(); 
	for (int i=1; i<eptCount;  i++) 
		{if (USBDevice->EndPoints[i]->Address ==(int (*x)))
			{*y=i;
			break;
			}
		}
	delete USBDevice;

	return;
}
