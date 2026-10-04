//[devicecount vID pID]=usbcheckchip;
//return 1 1204 34323, else error

#include <stdio.h>
#include "C:\Program Files\MATLAB\R2010b\extern\include\mex.h"
#include <windows.h>
#include <malloc.h>
#include <Setupapi.h>
#include "C:\Cypress\Cypress Suite USB 3.4.7\CyAPI\inc\CyAPI.h"


void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
  
{
	CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL); 
	int   devices = USBDevice->DeviceCount(); 
	double *y;
	plhs[0] = mxCreateDoubleMatrix(1,1, mxREAL);
	plhs[1] = mxCreateDoubleMatrix(1,1, mxREAL);
	plhs[2] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[4] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[5] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[6] = mxCreateDoubleMatrix(1,1, mxREAL);
	y = mxGetPr(plhs[0]);
	*y=devices;
	int   vID, pID, configcount, eptcount, intfccount, altintfccount; 
	vID = USBDevice->VendorID; 
    pID  = USBDevice->ProductID;
    configcount= USBDevice->ConfigCount();
    eptcount= USBDevice->EndPointCount();
    intfccount=USBDevice->IntfcCount();
    altintfccount=USBDevice->AltIntfcCount();
	y = mxGetPr(plhs[1]);
	*y=vID;
	y = mxGetPr(plhs[2]);
	*y=pID;
    y = mxGetPr(plhs[3]);
	*y=configcount;
       y = mxGetPr(plhs[4]);
	*y=eptcount;
           y = mxGetPr(plhs[5]);
	*y=intfccount;
           y = mxGetPr(plhs[6]);
	*y=altintfccount;
	delete USBDevice;
	return;
}
