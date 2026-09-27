//linesdone=usbdownload(codedata)
//linesdone: lines downloaded, 0:error


#include <stdio.h>
#include "C:\Program Files\MATLAB\R2010b\extern\include\mex.h"
#include "C:\Program Files\MATLAB\R2010b\extern\include\matrix.h"
#include <windows.h>
#include <malloc.h>
#include "C:\Cypress\Cypress Suite USB 3.4.7\CyAPI\inc\CyAPI.h"


void 
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
  
{
	CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL); 
    CCyControlEndPoint *ept=USBDevice->ControlEndPt;
    ept->ReqCode=0xa0;
    int i,index,elements[2],lines;
    BYTE *data,cpucs;
    LONG length;
//    short int *temp;
    double *x,*y;
    lines=mxGetM(prhs[0]);
//    int dim[2]={1,lines};   
//    plhs[0] = mxCreateNumericArray(2,dim,mxINT16_CLASS,mxREAL);
	plhs[0] = mxCreateDoubleMatrix(1,1, mxREAL);
    y = mxGetPr(plhs[0]);
    *y=0;
    length=1;
    ept->Value=0xe600;
    ept->Direction=DIR_FROM_DEVICE;
    ept->XferData(&cpucs,length);
    cpucs=cpucs|0x01;
    ept->Direction=DIR_TO_DEVICE;
    ept->XferData(&cpucs,length);
    for (i=0;i<lines;i++)
        {elements[0]=i;
        elements[1]=0;
        index= mxCalcSingleSubscript(prhs[0], 2, elements);
        length=*((LONG *)(mxGetData(mxGetCell(prhs[0], index))));
        if (length<=0) return;
        elements[1]=1;
        index= mxCalcSingleSubscript(prhs[0], 2, elements);
        ept->Value=*((WORD *)(mxGetData(mxGetCell(prhs[0], index))));
        elements[1]=2;
        index= mxCalcSingleSubscript(prhs[0], 2, elements);
        data=(BYTE *)(mxGetData(mxGetCell(prhs[0], index)));
        if (data==NULL) return;
        ept->XferData(data,length);
        if (length==0) return;
        *y=i;
//        y[i]=double (*temp);
        }
    ept->Value=0xe600;
    cpucs=cpucs&0xfe;
    length=1;
    ept->XferData(&cpucs,length);
/*	double *x;
    LONG *y,*z;
    int i,endpoint1,endpoint6;
    UCHAR *buf;
    LONG length,outlength =1;
    y=(LONG *)mxGetPr(plhs[1]);
    z=(LONG *)mxGetPr(plhs[2]);
	x = mxGetPr(prhs[0]);
    endpoint1=int (*x);
	x = mxGetPr(prhs[1]);
    endpoint6= int (*x);
    x = mxGetPr(prhs[2]);
    length=LONG (*x);
    dim[1]=int (length);
    length=length*2;
    plhs[0]=mxCreateNumericArray(2,dim,mxUINT16_CLASS,mxREAL);
    buf=(UCHAR *) mxGetPr(plhs[0]);
    USBDevice->EndPoints[endpoint1]->XferData(buf, outlength);
	*y=outlength;
    if (*y==0)
		return;
	USBDevice->EndPoints[endpoint6]->XferData(buf, length);
    *z=length;
    if (*z==0)
        return;*/
	delete USBDevice;

	return;
}
