function varargout = PUPradarGUI(varargin)
%PUPRADARGUI MATLAB code file for PUPradarGUI.fig
%      PUPRADARGUI, by itself, creates a new PUPRADARGUI or raises the existing
%      singleton*.
%
%      H = PUPRADARGUI returns the handle to a new PUPRADARGUI or the handle to
%      the existing singleton.
%
%      PUPRADARGUI('Property','Value',...) creates a new PUPRADARGUI using the
%      given property value pairs. Unrecognized properties are passed via`
%      varargin to PUPradarGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      PUPRADARGUI('CALLBACK') and PUPRADARGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in PUPRADARGUI.M with the given input
%      arguments.
% 
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PUPradarGUI

% Last Modified by GUIDE v2.5 20-Jan-2021 23:03:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PUPradarGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @PUPradarGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PUPradarGUI is made visible.
function PUPradarGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)
set(findall(handles.ParameterPanel, '-property', 'enable'), 'enable', 'off');
set(findall(handles.ChannelPanel, '-property', 'enable'), 'enable', 'off');
set(findall(handles.RecorderPanel, '-property', 'enable'), 'enable', 'off'); 
set(findall(handles.WaveformPanel, '-property', 'enable'), 'enable', 'off'); 
set(findall(handles.RangeProfilePanel, '-property', 'enable'), 'enable', 'off'); 
set(findall(handles.RangeVelocityPanel, '-property', 'enable'), 'enable', 'off'); 
set(findall(handles.DisplayPanel, '-property', 'enable'), 'enable', 'off'); 
set(findall(handles.DynamicRangePanel, '-property', 'enable'), 'enable', 'off');
set(handles.MessageWindow, 'String', ''); 
set(handles.MessageWindow, 'enable', 'off'); 
set(handles.togglebuttonStart, 'enable', 'off'); 

% handles.StreamX = 0;
% handles.StreamY = 0;
% handles.WaterfallX = 0;
% handles.WaterfallY = 0;
% handles.RangeX = 0;
% handles.RangeY = 0;
% handles.DopplerX = 0;
% handles.DopplerY = 0;


% Choose default command line output for PUPradarGUI
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PUPradarGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PUPradarGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonRefresh.
function pushbuttonRefresh_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRefresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%try
    %sdradar_init;
handles.RangeFFT_Size = 1024;

handles.VelocityFFT_Size = 1024;
handles.NewWaveformSawtooth =1;
handles.NewWaveformCW =1;
handles.NewRangeProfileSawtooth = 1;
handles.NewRangeProfileCW =1;
handles.NewWaterfallCW =1;
handles.NewRangeVelocitySawtooth = 1;
handles.model=' ';
[handles]=PUPradar_initiating(hObject, handles); 
[handles]=PUPradar_initiating(hObject, handles); 
while (handles.model==' ')
[handles]=PUPradar_initiating(hObject, handles); 
tt=tt+1;
if (tt>5)
    handles.model='no device is connected ';
end
end
handles.PowerRatio=4e2;
handles.RangeRatio=1.4;
% w512 = window(@hamming,512);
% w1024=window(@hamming,1024);
% [maskr,maskc]=meshgrid(w1024,w512);
% window2d=maskr.*maskc;
% M2DR=1-window2d;
% Mask2D=ones(512,1024);
% Mask2D(1:256, :)=Mask2D(1:256, :).*M2DR(257:512,:); %Direct coupling canceling mask
% handles.Mask2D=Mask2D;

w256 = window(@hamming,256);
w1024=window(@hamming,1024);
[maskr,maskc]=meshgrid(w256,w1024);
window2d=maskr.*maskc;
M2DR=1-window2d;
M2DR2=M2DR(520, :);
M2DR3=ones(512,1).*M2DR2;
Mask2D=ones(512,1024);
Mask2D(:, 375: 630)=Mask2D(:, 375: 630).*M2DR3;
handles.Mask2D=Mask2D;

set(handles.MessageWindow, 'enable', 'on'); 
set(handles.MessageWindow,'String',handles.model,'ForegroundColor','black');
handles.togglebuttonStart.Enable = 'on';
set(handles.radiobuttonSawtooth,'Value',1);
set(handles.radiobuttonCW,'Value',0);
set(handles.SweepTime,'Value',1); 
set(handles.SamplingNumber,'Value',4)
set(handles.DynamicRangeHighSet, 'Value', 5.0);
set(handles.DynamicRangeLowSet, 'Value', 4.9);
% catch
%     set(handles.MessageWindow, 'enable', 'on');
%     handles.model='No PUPradar Device found'
%     set(handles.MessageWindow,'String', handles.model);
%     set(handles.togglebuttonStart, 'Enable', 'off', 'String', 'Start'); 
%     handles.togglebuttonStart.Enable = 'off';
% end
guidata(hObject, handles);

%handles

% --- Executes on button press in togglebuttonStart.
function togglebuttonStart_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.togglebuttonStart.Value == handles.togglebuttonStart.Min
    %button poped up
    set(handles.togglebuttonStart,'String', 'Start');
    handles.togglebuttonStart.TooltipString = 'push to Start'; 
    set(findall(handles.ParameterPanel, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.ChannelPanel, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.DisplayPanel, '-property', 'enable'), 'enable', 'off'); 
    set(findall(handles.DynamicRangePanel, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.RecorderPanel, '-property', 'enable'), 'enable', 'off'); 
%    set(findall(handles.RecordTimeSet, '-property', 'enable'), 'enable', 'off'); 
    set(findall(handles.OperationPanel, '-property', 'enable'), 'enable', 'on');

    handles.NewWaterfallCW =1;
    handles.NewRangeProfileSawtooth=1;
    guidata(hObject, handles);
%    h1=handles.NewWaterfallCW
else
    set(handles.togglebuttonStart,'String', 'Stop'); 
    handles.togglebuttonStart.TooltipString = 'push to Stop'; 
    set(findall(handles.ParameterPanel, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.ChannelPanel, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.TransmitterSet, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.ReceiverSet, '-property', 'enable'), 'enable', 'on'); 
    set(findall(handles.DisplayPanel, '-property', 'enable'), 'enable', 'on'); 
    set(findall(handles.DynamicRangePanel, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.RecorderPanel, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.WaveformPanel, '-property', 'enable'), 'enable', 'on'); 
    set(findall(handles.RangeProfilePanel, '-property', 'enable'), 'enable', 'on'); 
    set(findall(handles.RangeVelocityPanel, '-property', 'enable'), 'enable', 'on'); 
    handles.WaveformAxesRebuild=1;
 
    handles.NewWaterfallCW =1;
    handles.NewRangeProfileSawtooth=1;
 while   handles.togglebuttonStart.Value ==handles.togglebuttonStart.Max         
    %setup Active Parameters
    RangeFFT_Size = handles.RangeFFT_Size;
    VelocityFFT_Size=handles.VelocityFFT_Size ; 
    LightSpeed=3e8;
    [handles]=SetActiveParameters(hObject, handles);
    % send MD,ST,SN,Tx,Rx parameters to MCU,
  
    Send_Basic_Parameter( hObject, handles); 
    %Send PLL registry parameters to MCU  
    LAMS=handles.ActiveModulationString; %LocalActiveModulation 
    LAMSV=handles.ActiveModulationValue; 
    LAPR=handles.PowerRatio;
    LARR=handles.RangeRatio;
    Mask2D=handles.Mask2D;
    if strcmp(LAMS,'Sawtooth')
        handles.ActiveModulationValue=0;
        [handles]=Send_PLL_Sawtooth( hObject, handles);
    end
    if strcmp(LAMS,'CW')
        set(findall(handles.FrequencyHigh, '-property', 'enable'), 'enable', 'off');
        handles.ActiveModulationValue=3;      
        [handles]=Send_PLL_CW( hObject, handles);
    end

    if (LAMSV == 0) %% Sawtooth
        LAFL=handles.ActiveFrequencyLow;
        LAFH=handles.ActiveFrequencyHigh;   
        LABW=handles.ActiveBandwidth;
        LASTV=handles.ActiveSweepTimeValue;
        LAST=handles.ActiveSweepTime;
        LASNV=handles.ActiveSamplingNumberValue ;
        LBSN=handles.BASN;
        LASN=handles.SN_Selections(LASNV);
%        LocalActivePLLSweepStop=handles.ActivePLLSweepStop;
        LocalActiveRxValue=handles.ActiveRxValue;
        LANR=handles.ActiveNum_Rx;
        LocalActiveTxValue=handles.ActiveTxValue;
        LANT=handles.ActiveNum_Tx;  
        LADCR=handles.ActiveDisplayChannelRx;  
        LADCT=handles.ActiveDisplayChannelTx;    
        handles.NumSweeps=64;
        handles.NewWaveformCW =1;
        handles.NewRangeProfileCW =1;
        handles.NewWaterfallCW =1;
        [ComplexDataTx1, ComplexDataTx2, NumSweeps] = GetComplexData( handles); 
        handles.CenterFrequency = LAFL +LABW/2;
        LACF= LAFL +LABW/2;      %Local Center Frequency 
        SamplingRate = LASN/LAST;
        RangeMax = 3e8/ (2*LABW) *  LASN/2;
        PRF = 1/LAST/LANT;  %pulse Repeat Frequency
        VelocityMax = PRF/2 * 3e8/LACF/2;       
        DopplerFrequency = 1/LAST;
         
%       waveform display
        N_Average = 20; %Averaging
        if LADCT=='Tx1'         %LocalActiveDisplayChannelTx
            if LANR==1
                 RealData_I=real(ComplexDataTx1(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:N_Average));
                 RawData_Complex=ComplexDataTx1(1:LASN,:);
            elseif LANR==2
                 if (LADCR=='Rx1') 
                 RealData_I=real(ComplexDataTx1(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:N_Average)); 
                 RawData_Complex=ComplexDataTx1(1:LASN,:);
                 elseif (LADCR=='Rx3') 
                 RealData_I=real(ComplexDataTx1(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:N_Average)); 
                 RawData_Complex=ComplexDataTx1(1:LASN,:);                     
                 elseif (LADCR=='Rx2')                   
                 RealData_I=real(ComplexDataTx1(LASN+1:LASN*2,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(LASN+1:LASN*2,1:N_Average));
                 RawData_Complex=ComplexDataTx1(LASN+1:LASN*2,:);                     
                 elseif (LADCR=='Rx4')
                 RealData_I=real(ComplexDataTx1(LASN+1:LASN*2,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(LASN+1:LASN*2,1:N_Average));
                 RawData_Complex=ComplexDataTx1(LASN+1:LASN*2,:);
                 end
             elseif LANR==4 
                 if LADCR=='Rx1'  
                 RealData_I=real(ComplexDataTx1(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:N_Average)); 
                 RawData_Complex=ComplexDataTx1(1:LASN,:);
                 elseif LADCR=='Rx2'
                 RealData_I=real(ComplexDataTx1(LASN+1:LASN*2,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(LASN+1:LASN*2,1:N_Average));
                 RawData_Complex=ComplexDataTx1(LASN+1:LASN*2,:);
                 elseif LADCR=='Rx3'  
                 RealData_I=real(ComplexDataTx1(LASN*2+1:LASN*3,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(LASN*2+1:LASN*3,1:N_Average)); 
                 RawData_Complex=ComplexDataTx1(LASN*2+1:LASN*3,:);
                 elseif LADCR=='Rx4'
                 RealData_I=real(ComplexDataTx1(LASN*3+1:LASN*4,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx1(LASN*3+1:LASN*4,1:N_Average));
                 RawData_Complex=ComplexDataTx1(LASN*3+1:LASN*4,:);                 
                 end                 
            end            
        elseif LADCT=='Tx2' 
            if LANR==1
                 RealData_I=real(ComplexDataTx2(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:N_Average)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);
            elseif LANR==2                
                 if (LADCR=='Rx1')  
                 RealData_I=real(ComplexDataTx2(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:N_Average)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);
                 elseif (LADCR=='Rx3')   
                 RealData_I=real(ComplexDataTx2(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:N_Average)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);                                  
                 elseif (LADCR=='Rx2')
                 RealData_I=real(ComplexDataTx2(LASN+1:LASN*2,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(LASN+1:LASN*2,1:N_Average));
                 RawData_Complex=ComplexDataTx2(LASN+1:LASN*2,:);
                 elseif (LADCR=='Rx4')
                 RealData_I=real(ComplexDataTx2(LASN+1:LASN*2,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(LASN+1:LASN*2,1:N_Average));
                 RawData_Complex=ComplexDataTx2(LASN+1:LASN*2,:);                                          
                 end
             elseif LANR==4 
                 if LADCR=='Rx1'  
                 RealData_I=real(ComplexDataTx2(1:LASN,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:N_Average)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);
                 elseif LADCR=='Rx2'
                 RealData_I=real(ComplexDataTx2(LASN+1:LASN*2,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(LASN+1:LASN*2,1:N_Average));
                 RawData_Complex=ComplexDataTx2(LASN+1:LASN*2,:);
                 elseif LADCR=='Rx3'  
                 RealData_I=real(ComplexDataTx2(LASN*2+1:LASN*3,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(LASN*2+1:LASN*3,1:N_Average)); 
                 RawData_Complex=ComplexDataTx2(LASN*2+1:LASN*3,:);
                 elseif LADCR=='Rx4'
                 RealData_I=real(ComplexDataTx2(LASN*3+1:LASN*4,1:N_Average));  
                 ImagData_Q=imag(ComplexDataTx2(LASN*3+1:LASN*4,1:N_Average));
                 RawData_Complex=ComplexDataTx2(LASN*3+1:LASN*4,:);                 
                 end                 
            end            
        end
        RawData_I = mean(RealData_I,2);
        RawData_Q = mean(ImagData_Q,2); 
        [b,a]=butter(4,[0.04,0.85]);
        RawData_I_Waveform =RawData_I(LASN/4+1:LASN/4*3); %take out the linear sweeping part
        RawData_I_Waveform = filter(b,a, RawData_I_Waveform-mean( RawData_I_Waveform));               
        RawData_I_Waveform =interp(RawData_I_Waveform,2); 
        RawData_Q_Waveform = RawData_Q(LASN/4+1:LASN/4*3); %take out the linear sweeping part
        RawData_Q_Waveform = filter(b,a, RawData_Q_Waveform-mean( RawData_Q_Waveform));
        RawData_Q_Waveform =interp(RawData_Q_Waveform,2);   

%================================Waveform plot==================             
        axes(handles.AxesWaveform);  
        cla(handles.AxesWaveform, 'reset')
        xlabel('Samples per sweep');
        ylabel('Amplitude');
        set(handles.AxesWaveform, 'XGrid','on','YGrid', 'on', 'GridColor', [0.23 0.44 0.34], 'GridLineStyle', '-', 'GridAlpha', 0.8);
        set(handles.AxesWaveform,'Color','Black');
        %[rx,ry]=size(RawData_I)
        Xaxis = 1:LASN; %1:round(Sweep_N/4/dec);
        Yaxis = NaN(2, LASN);%NaN(2, round(Sweep_N/4/dec));
        FigureStyle = line(Xaxis, Yaxis, 'LineWidth', 1);
        FigureStyle(1).Color = [0 1 0];
        FigureStyle(2).Color = [1 1 0];
        axis(handles.AxesWaveform, [1 LASN -inf inf]);
        FigureStyle(1).YData = RawData_I_Waveform- mean( RawData_I_Waveform);
        FigureStyle(2).YData = RawData_Q_Waveform- mean( RawData_Q_Waveform);                
        drawnow               
 %===========================Range profile processing======================
        RangeResolution = SamplingRate / RangeFFT_Size; % frequency resolution in range
        DopplerResolution = PRF / VelocityFFT_Size; % frequency resolution in Doppler      
        RawDataMatrix = RawData_Complex-mean(RawData_Complex, 2);
        RawDataMatrix = filter(b,a,RawDataMatrix);
        % Range profiles    
        RangeDataFFT = fft(RawDataMatrix, RangeFFT_Size, 1);
        RangeDataFFT = RangeDataFFT(1:RangeFFT_Size/2, :);
        RangeDataFFT =  RangeDataFFT - mean(RangeDataFFT, 2);  
        RangePower=abs(RangeDataFFT(:,32));
%        save RangePower RangePower
        [RangePowerMax, ~] = max(RangePower);
        [RangePowerMin, ~] = min(RangePower);
        RangePower=(RangePower-RangePowerMin)/(RangePowerMax-RangePowerMin)*45+5;  
        [RangePowerMin, ~] = min(RangePower);
        [RangePowerMax, ~] = max(RangePower);         
        
 %===========================Range velocity processing======================        
        RangeDopplerPower = abs(fftshift(fft(RangeDataFFT,VelocityFFT_Size, 2), 2)).^2/(DopplerResolution*RangeResolution); 
        [sizex,sizey]=size(RangeDopplerPower);      
        RangeDopplerPower = (RangeDopplerPower.*Mask2D).*blackmanharris(sizey)'/LAPR;          
        RangeDopplerPowerLog=40*log10(RangeDopplerPower);               
        DopplerAxis = linspace(-PRF/2,PRF/2,VelocityFFT_Size)*3e8*LANT/LACF/2;        
        RangeAxis = linspace(0, SamplingRate/4, RangeFFT_Size/2)*3e8*LAST/(2*LABW)*LARR;        
        %using the data in whole sweep(not cropping the 1/4-3/4 part), RangeAxis should be SamplingRate/2%
        [V1,I1]=max(RangeDopplerPower);
        [V2,I2]=max(V1);
        X1=I1(I2);
        Y1=I2;
        TargetRange=RangeAxis(X1);
        TargetVelocity=DopplerAxis(Y1);  
             
%====================range profile plot===================================       
        axes(handles.AxesRangeProfile);
        cla(handles.AxesRangeProfile, 'reset');
        set(handles.AxesRangeProfile, 'Color', 'k');
        handles.FigureStyleRangeProfile = line(RangeAxis, RangePower, 'LineWidth', 1);       
        handles.FigureStyleRangeProfile.Color = [0 1 0];
        xlabel('Range (meters)');
        ylabel('Power/frequency (dB/Hz)');
        hold on;
        grid on; 
        set(handles.AxesRangeProfile, 'GridColor', [0.23 0.44 0.34], 'GridLineStyle', '--', 'GridAlpha', 0.8);   
        set(handles.AxesRangeProfile,'Color','Black');
          
%       below is the position bar for range of the Target
        handles.FigureStylePositionBar = line([TargetRange TargetRange],[-100 100], 'LineStyle', ':', 'Color', [1 1 0], 'LineWidth', 1);
      	handles.FigureStyleePositionBar.XData = [TargetRange, TargetRange];    
        handles.FigureStyleePositionBar.YData = [RangePowerMin RangePowerMax]; 
 
        label = sprintf('Detected Range: %4.2f m ', TargetRange);
        handles.FigureStyleText = text(TargetRange, RangePowerMax*0.95, label, 'Color', [1 1 0]);
        set(handles.AxesRangeProfile,'Color','Black');
        axis(handles.AxesRangeProfile, [0, RangeMax*LARR/2, -5, 60]);
        
        drawnow        
  %==================Range Velocity Plot=================================          
        axes(handles.AxesRangeVelocity);    

        cla(handles.AxesRangeVelocity, 'reset') 
        imagesc(DopplerAxis, RangeAxis, RangeDopplerPowerLog);
        axis xy;
        hold on
        plot(0,TargetRange,'go','linewidth',2);
        plot(TargetVelocity,1,'ro','linewidth',2);                        
        AutoDRMaxVal = get(handles.DynamicRangeHighSet, 'Value' );
        AutoDRMinVal = get(handles.DynamicRangeLowSet, 'Value'); 
        if AutoDRMaxVal>=AutoDRMinVal
        set(gca, 'CLim', [AutoDRMinVal*10, AutoDRMaxVal*20]);  
        end
        xlabel('Velocity (m/s)');
        ylabel('Range (m)');
        drawnow    

    elseif  (LAMSV == 3) %% CW
        LAFL=handles.ActiveFrequencyLow;
        LACF=LAFL;   %Local Active Center Frequency
        LASTV=handles.ActiveSweepTimeValue;
        LAST=handles.ActiveSweepTime;
        LASNV=handles.ActiveSamplingNumberValue ;
        LBSN=handles.BASN;
        LASN=handles.SN_Selections(LASNV);
        LocalActivePLLSweepStop=handles.ActivePLLSweepStop;
        LocalActiveRxValue=handles.ActiveRxValue;
        LANR=handles.ActiveNum_Rx;
        LocalActiveTxValue=handles.ActiveTxValue;
        LANT=handles.ActiveNum_Tx;  
        LADCR=handles.ActiveDisplayChannelRx;  
        LADCT=handles.ActiveDisplayChannelTx;    
        handles.NumSweeps=128;
        FrameHeight=100;  
        handles.NewWaveformSawtooth =1;
        handles.NewRangeProfileSawtooth = 1;
        handles.NewRangeVelocitySawtooth=1;  
        SamplingRate = LASN/LAST;

        DecimationCW = LASN/256*64;
        DeciSamplingRate = SamplingRate/DecimationCW; % used only for CW decimation
        DopplerMax = DeciSamplingRate/2;
        VelocityMax = DopplerMax*3e8*LANT/LACF/2;
        [ComplexDataTx1, ComplexDataTx2, NumSweeps] = GetComplexData( handles);   
        [~, YsizeTx1]=size(ComplexDataTx1);
        [~, YsizeTx2]=size(ComplexDataTx2);
            
        if LADCT=='Tx1'         %LocalActiveDisplayChannelTx
            if LANR==1
                 RealData_I=real(ComplexDataTx1(1:LASN,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:YsizeTx1)); 
                 RawData_Complex=ComplexDataTx1(1:LASN,:);
            elseif LANR==2
                 if (LADCR=='Rx1') 
                 RealData_I=real(ComplexDataTx1(1:LASN,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:YsizeTx1)); 
                 RawData_Complex=ComplexDataTx1(1:LASN,:);
                 elseif (LADCR=='Rx3')
                 RealData_I=real(ComplexDataTx1(1:LASN,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:YsizeTx1)); 
                 RawData_Complex=ComplexDataTx1(1:LASN,:);      
                 elseif (LADCR=='Rx2')
                 RealData_I=real(ComplexDataTx1(LASN+1:LASN*2,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(LASN+1:LASN*2,1:YsizeTx1));
                 RawData_Complex=ComplexDataTx1(LASN+1:LASN*2,:);
                 elseif (LADCR=='Rx4')
                 RealData_I=real(ComplexDataTx1(LASN+1:LASN*2,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(LASN+1:LASN*2,1:YsizeTx1));
                 RawData_Complex=ComplexDataTx1(LASN+1:LASN*2,:);                     
                 end
             elseif LANR==4 
                 if LADCR=='Rx1'  
                 RealData_I=real(ComplexDataTx1(1:LASN,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(1:LASN,1:YsizeTx1)); 
                 RawData_Complex=ComplexDataTx1(1:LASN,:);
                 elseif LADCR=='Rx2'
                 RealData_I=real(ComplexDataTx1(LASN+1:LASN*2,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(LASN+1:LASN*2,1:YsizeTx1));
                 RawData_Complex=ComplexDataTx1(LASN+1:LASN*2,:);
                 elseif LADCR=='Rx3'  
                 RealData_I=real(ComplexDataTx1(LASN*2+1:LASN*3,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(LASN*2+1:LASN*3,1:YsizeTx1)); 
                 RawData_Complex=ComplexDataTx1(LASN*2+1:LASN*3,:);
                 elseif LADCR=='Rx4'
                 RealData_I=real(ComplexDataTx1(LASN*3+1:LASN*4,1:YsizeTx1));  
                 ImagData_Q=imag(ComplexDataTx1(LASN*3+1:LASN*4,1:YsizeTx1));
                 RawData_Complex=ComplexDataTx1(LASN*3+1:LASN*4,:);                 
                 end                 
            end            
        elseif LADCT=='Tx2' 
            if LANR==1
                 RealData_I=real(ComplexDataTx2(1:LASN,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:YsizeTx2)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);
            elseif LANR==2
                 if (LADCR=='Rx1') 
                 RealData_I=real(ComplexDataTx2(1:LASN,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:YsizeTx2)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);
                 elseif(LADCR=='Rx3')
                 RealData_I=real(ComplexDataTx2(1:LASN,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:YsizeTx2)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);                         
                 elseif (LADCR=='Rx2')
                 RealData_I=real(ComplexDataTx2(LASN+1:LASN*2,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(LASN+1:LASN*2,1:YsizeTx2));
                 RawData_Complex=ComplexDataTx2(LASN+1:LASN*2,:);
                 elseif (LADCR=='Rx4')
                 RealData_I=real(ComplexDataTx2(LASN+1:LASN*2,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(LASN+1:LASN*2,1:YsizeTx2));
                 RawData_Complex=ComplexDataTx2(LASN+1:LASN*2,:);                        
                 end
             elseif LANR==4 
                 if LADCR=='Rx1'  
                 RealData_I=real(ComplexDataTx2(1:LASN,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(1:LASN,1:YsizeTx2)); 
                 RawData_Complex=ComplexDataTx2(1:LASN,:);
                 elseif LADCR=='Rx2'
                 RealData_I=real(ComplexDataTx2(LASN+1:LASN*2,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(LASN+1:LASN*2,1:YsizeTx2));
                 RawData_Complex=ComplexDataTx2(LASN+1:LASN*2,:);
                 elseif LADCR=='Rx3'  
                 RealData_I=real(ComplexDataTx2(LASN*2+1:LASN*3,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(LASN*2+1:LASN*3,1:YsizeTx2)); 
                 RawData_Complex=ComplexDataTx2(LASN*2+1:LASN*3,:);
                 elseif LADCR=='Rx4'
                 RealData_I=real(ComplexDataTx2(LASN*3+1:LASN*4,1:YsizeTx2));  
                 ImagData_Q=imag(ComplexDataTx2(LASN*3+1:LASN*4,1:YsizeTx2));
                 RawData_Complex=ComplexDataTx2(LASN*3+1:LASN*4,:);                 
                 end                 
            end            
        end                         
        RawData_I=reshape( RealData_I, 1,[]);    
        RawData_Q=reshape( ImagData_Q, 1,[]);     
        RawData_I = RawData_I - mean(RawData_I);
        RawData_Q = RawData_Q - mean(RawData_Q);               
        Mean_I = mean(RawData_I);
        Mean_Q = mean(RawData_Q);              
        I2_bar = mean((RawData_I-Mean_I).^2);
        Q2_bar = mean((RawData_Q-Mean_Q).^2);
        IQ_bar = mean((RawData_I-Mean_I).*(RawData_Q-Mean_Q));
        D_bar = IQ_bar/I2_bar;
        C_bar = sqrt(Q2_bar/I2_bar-D_bar^2);
        D_AmpImb = sqrt(C_bar^2+D_bar^2)-1;
        phi = atan(D_bar/C_bar);
        RawData_I = RawData_I-Mean_I;
        RawData_Q = ((RawData_Q-Mean_Q)/(1+D_AmpImb)-RawData_I*sin(phi))/cos(phi);
        WaveformCW = RawData_I+1i*RawData_Q; % IQ imbalance correction

        DecimationDataCW = decimate(WaveformCW, DecimationCW);   
        DecimationDataCW = DecimationDataCW.*blackmanharris(length(DecimationDataCW))';
        Xtime = (1:length(DecimationDataCW))/DeciSamplingRate;
%       Xspeed = linspace(-DeciSamplingRate/2,DeciSamplingRate/2,Doppler_FFT_Size)*LightSpeed/(2*LAFL);
%       [MaxValue,index] = max(FFTsignal);        

 %================================plot waveform======================================           
        axes(handles.AxesWaveform);                                            
        DecimationDataCW_I = real(DecimationDataCW);
        DecimationDataCW_Q = imag(DecimationDataCW);
%       if  handles.NewWaveformCW ==1
        cla(handles.AxesWaveform, 'reset')
        set(handles.AxesWaveform,'Color','Black');
        Yaxis = NaN(2, length(Xtime));
        handles.FigureStyleW = line(Xtime, Yaxis, 'LineWidth', 1);
        handles.FigureStyleW(1).Color = [1 1 0];
        handles.FigureStyleW(2).Color = [0 1 0];
        % Amp_max = max(max(I_DecimationDataCW), max(Q_DecimationDataCW));
        axis([0 max(Xtime) -inf inf]);
        xlabel('Time(s)');
        ylabel('Amplitude');
        set(handles.AxesWaveform, 'XGrid','off', 'YGrid', 'on', 'GridColor', [0.23 0.44 0.34], 'GridLineStyle', '--', 'GridAlpha', 0.8)
        
        handles.FigureStyleW(1).YData = DecimationDataCW_I;
        handles.FigureStyleW(2).YData = DecimationDataCW_Q;
        drawnow     
        guidata(hObject, handles);    
        
%===============================plot Range Profile=================
        axes(handles.AxesRangeProfile); 
        VelocityFFT_Size=handles.VelocityFFT_Size;  %1024
        DopplerResolution = DeciSamplingRate / VelocityFFT_Size;
        RangePower=(((abs(fftshift(fft(DecimationDataCW,VelocityFFT_Size))).^2/DopplerResolution)+eps));
        RangePower = 10*log10(RangePower*5);
        [RangePowerMax, RangePowerMaxIndex] = max(RangePower);
        vel_axis = linspace(-VelocityMax, VelocityMax, VelocityFFT_Size);
        TargetVelocity = vel_axis(RangePowerMaxIndex);
        cla(handles.AxesRangeProfile, 'reset');
        set(handles.AxesRangeProfile, 'Color', 'k');
        handles.FigureStyleV = line(vel_axis, RangePower, 'LineWidth', 1); 
        handles.FigureStyleV.Color = [0 1 0];
        hold on;

        axis([-VelocityMax, VelocityMax, 0, max(RangePowerMax+5, 3)]);
        xlabel('Velocity (m/s)');
        ylabel('Intensity (dB)');
%       handles.FigureStyleV2 = line([vel_max vel_max],[0 Doppler_psd_max], 'LineStyle', '--', 'Color', [1 1 0], 'LineWidth', 3);
        label = sprintf('Detected Velocity: %4.2f m/s ', TargetVelocity);
        handles.TextStyleV = text(TargetVelocity+1, RangePowerMax-1, label, 'Color', [1 1 0]);
%       leg_txt = strcat('Max velocity: ', num2str(vel_max), ' m/s');
%       legend({leg_txt}, 'FontSize',12, 'TextColor', 'k', 'Color', [0.65,0.65,0.65])
        grid on;
        set(handles.AxesRangeProfile, 'GridColor', [0.23 0.44 0.34], 'GridLineStyle', '--', 'GridAlpha', 0.8)
        handles.TextStyleV.String = label;
        handles.TextStyleV.Position = [TargetVelocity+1, RangePowerMax-1];
        handles.FigureStyleV,CData= RangePower;  
        drawnow
        guidata(hObject, handles);  
%=====================================plot waterfall============================================                      
        axes(handles.AxesRangeVelocity);  
        set(handles.RangeVelocityPanel,'Title','VelocityWaterfall');
        set(handles.AxesRangeVelocity, 'Color', 'k');          
        if  handles.NewWaterfallCW ==1
            cla(handles.AxesRangeVelocity, 'reset') 
            Velocity_WF = zeros(FrameHeight, VelocityFFT_Size);
            handles.ImageStyleVelocityWaterfall =  imagesc(vel_axis, linspace(0, FrameHeight-1, FrameHeight), Velocity_WF);
            axis xy;                          
%           shading(handles.AxesRangeVelocity, 'interp');
            xlabel('Velocity (m/s)');
            ylabel('Frame') 
            handles.NewWaterfallCW =0;
            guidata(hObject, handles);
        else
            Velocity_WF(2:FrameHeight,:) = Velocity_WF(1:FrameHeight-1,:);
            Velocity_WF(1,:) = RangePower;
            handles.ImageStyleVelocityWaterfall.CData = Velocity_WF;
            axis([-VelocityMax, VelocityMax, 0, FrameHeight]);
        end
        drawnow                                     
        AutoDRMaxVal = get(handles.DynamicRangeHighSet, 'Value' );
        AutoDRMinVal = get(handles.DynamicRangeLowSet, 'Value');    
        if AutoDRMaxVal>=AutoDRMinVal
            set(gca, 'CLim', [AutoDRMinVal*10, AutoDRMaxVal*20]);  
        end
        guidata(hObject, handles);
        drawnow                   
    end          
 end   
end


function MessageWindow_Callback(hObject, ~, handles)
% hObject    handle to MessageWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.MessageWindow,'String',handles.model);
% Hints: get(hObject,'String') returns contents of MessageWindow as text
%        str2double(get(hObject,'String')) returns contents of MessageWindow as a double


% --- Executes during object creation, after setting all properties.
function MessageWindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MessageWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in SweepTime.
function SweepTime_Callback(hObject, ~, handles)
% hObject    handle to SweepTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
LANR=handles.ActiveNum_Rx;
switch LANR
    case 1
        switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;  %base Sampling Number for 0.5ms
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 2  %1ms
            handles.ActiveSweepTime=1e-3;
            handles.BASN = 2048;%base Sampling Number for 1ms
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 3  %2ms
            handles.ActiveSweepTime=2e-3;
            handles.BASN = 4096;%base Sampling Number for 2ms
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
            set(handles.SamplingNumber, 'Value', 4);
            handles.ActiveSamplingNumber = 256;
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;
            handles.BASN = 8192;%base Sampling Number for 4ms
            handles.SN_Selections =  [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;
            handles.BASN = 16384; %base Sampling Number for 8ms
            handles.SN_Selections =[16384, 8192, 4096, 2048];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
        end
    
    case 2
        switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 512;    %base SamplinNumber=512, half for Num_Rx=2
            handles.SN_Selections = [512, 256, 128, 64];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);  %tag: SamplinNumber
       
        case 2  %1ms
            handles.ActiveSweepTime=1e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;   %base SamplinNumber=1024, half for Num_Rx=2
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
 
        case 3  %2ms
            handles.ActiveSweepTime=2e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 2048; %base SamplinNumber=2048, half for Num_Rx=2
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
          
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 4096;
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 8192;  %base SamplinNumber=8192, half for Num_Rx=2
            handles.SN_Selections = [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
        end 
        
    case 4
        switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN =256;    %base SamplinNumber=512, half for Num_Rx=2
            handles.SN_Selections = [256, 128, 64, 32];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);  %tag: SamplinNumber
       
        case 2  %1ms
            handles.ActiveSweepTime=1e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 512;   %base SamplinNumber=1024, half for Num_Rx=2
            handles.SN_Selections = [512, 256, 128, 64];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
 
        case 3  %2ms
            handles.ActiveSweepTime=2e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024; %base SamplinNumber=2048, half for Num_Rx=2
            handles.SN_Selections =  [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
          
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 2048;
            handles.SN_Selections = [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 4096;  %base SamplinNumber=8192, half for Num_Rx=2
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
  
        end
    
end

set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
        
% Update handles
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SweepTime_CreateFcn(hObject, ~, handles)
% hObject    handle to SweepTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in SamplingNumber.
function SamplingNumber_Callback(hObject, eventdata, handles)
% hObject    handle to SamplingNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveSamplingNumberValue= get(handles.SamplingNumber,'Value');
LASNV=handles.ActiveSamplingNumberValue;  % LocalActiveSamplingNumber

LASNV_Output=hex2dec('E300')+LASNV;
ForwardData=zeros(1024,1)+LASNV_Output;
instruction = uint16(ForwardData);
OutLength=miniradarputdata(instruction,handles.EndPoint2_Num);

% Update handles
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function SamplingNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SamplingNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FrequencyLow.
function FrequencyLow_Callback(hObject, eventdata, handles)
% hObject    handle to FrequencyLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ActiveFrequencyLowValue= get(handles.FrequencyLow,'Value');
LAFHV=handles.ActiveFrequencyHighValue;
LAFLV=handles.ActiveFrequencyLowValue;
if LAFLV>=LAFHV
    if LAFHV<=1
    set(handles.FrequencyLow,'Value',1); 
    handles.ActiveFrequencyLowValue= 1;
    set(handles.FrequencyHigh,'Value',2); 
    handles.ActiveFrequencyHighValue= 2;
    else      
    set(handles.FrequencyLow,'Value',LAFHV-1); 
    handles.ActiveFrequencyLowValue= LAFHV-1;
    end
end 

%Set Active FrequencyHigh
switch handles.ActiveFrequencyHighValue   
    case 1
        handles.ActiveFrequencyHigh=24.0e9;  
    case 2
        handles.ActiveFrequencyHigh=24.25e9;               
    case 3
        handles.ActiveFrequencyHigh=24.5e9;
    case 4
        handles.ActiveFrequencyHigh=24.75e9;
    case 5                
        handles.ActiveFrequencyHigh=25.0e9;
    case 6                
        handles.ActiveFrequencyHigh=25.25e9;                
    case 7                
        handles.ActiveFrequencyHigh=25.5e9;
    case 8                
        handles.ActiveFrequencyHigh=25.75e9;
    case 9        
        handles.ActiveFrequencyHigh=26.0e9;
end

%Set Active FrequencyLow
switch handles.ActiveFrequencyLowValue  
    case 1
        handles.ActiveFrequencyLow=24.0e9;  
    case 2
        handles.ActiveFrequencyLow=24.25e9;               
    case 3
        handles.ActiveFrequencyLow=24.5e9;
    case 4
        handles.ActiveFrequencyLow=24.75e9;
    case 5                
        handles.ActiveFrequencyLow=25.0e9;
    case 6                
        handles.ActiveFrequencyLow=25.25e9;                
    case 7                
        handles.ActiveFrequencyLow=25.5e9;
    case 8                
        handles.ActiveFrequencyLow=25.75e9;
    case 9        
        handles.ActiveFrequencyLow=26.0e9;
end 


% Update handles before use function 'Send_PLL_Sawtooth' and 'Send_PLL_CW'
guidata(hObject, handles); 

% Update handles
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function FrequencyLow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrequencyLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FrequencyHigh.
function FrequencyHigh_Callback(hObject, eventdata, handles)
% hObject    handle to FrequencyHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveFrequencyHighValue= get(handles.FrequencyHigh,'Value');
LAFHV=handles.ActiveFrequencyHighValue;
LAFLV=handles.ActiveFrequencyLowValue;
if LAFHV<=LAFLV
    if LAFLV==9
    set(handles.FrequencyLow,'Value',8);
    set(handles.FrequencyHigh,'Value',19); 
    handles.ActiveFrequencyLowValue=8;
    handles.ActiveFrequencyHighValue=9;
    else
    set(handles.FrequencyHigh,'Value',LAFLV+1); 
    handles.ActiveFrequencyHighValue= LAFLV+1;
    end
end

switch handles.ActiveFrequencyHighValue 
    case 1
        handles.ActiveFrequencyHigh=24.0e9;  
    case 2
        handles.ActiveFrequencyHigh=24.25e9;               
    case 3
        handles.ActiveFrequencyHigh=24.5e9;
    case 4
        handles.ActiveFrequencyHigh=24.75e9;
    case 5                
        handles.ActiveFrequencyHigh=25.0e9;
    case 6                
        handles.ActiveFrequencyHigh=25.25e9;                
    case 7                
        handles.ActiveFrequencyHigh=25.5e9;
    case 8                
        handles.ActiveFrequencyHigh=25.75e9;
    case 9        
        handles.ActiveFrequencyHigh=26.0e9;
end
%Set Active FrequencyLow
switch handles.ActiveFrequencyLowValue  
    case 1
        handles.ActiveFrequencyLow=24.0e9;  
    case 2
        handles.ActiveFrequencyLow=24.25e9;               
    case 3
        handles.ActiveFrequencyLow=24.5e9;
    case 4
        handles.ActiveFrequencyLow=24.75e9;
    case 5                
        handles.ActiveFrequencyLow=25.0e9;
    case 6                
        handles.ActiveFrequencyLow=25.25e9;                
    case 7                
        handles.ActiveFrequencyLow=25.5e9;
    case 8                
        handles.ActiveFrequencyLow=25.75e9;
    case 9        
        handles.ActiveFrequencyLow=26.0e9;
end 


% Update handles before use function 'Send_PLL_Sawtooth' 
guidata(hObject, handles); 
%Send_PLL_Sawtooth( hObject, handles);
  
% Update handles
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function FrequencyHigh_CreateFcn(hObject, ~, handles)
% hObject    handle to FrequencyHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobuttonTx1.
function radiobuttonTx1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonTx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobuttonTx1
Transmitter = get(handles.TransmitterSet,'SelectedObject'); 
%TransmitterString=hObject.String
handles.ActiveTransmitterString=Transmitter.String;
handles.ActiveTxValue=1;
handles.ActiveNum_Tx=1;
set(findall(handles.radiobuttonDTx1, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDTx2, '-property', 'enable'), 'enable', 'off');
set(handles.radiobuttonDTx1, 'value', 1);
set(handles.radiobuttonDTx2, 'value', 0);         
handles.ActiveDisplayChannelTx='Tx1';

LocalActiveTxValue=handles.ActiveTxValue;
Tx_Output=hex2dec('E400')+LocalActiveTxValue;
ForwardData=zeros(1024,1)+ Tx_Output;

Tx_instruction = uint16(ForwardData);
OutLength=miniradarputdata(Tx_instruction,handles.EndPoint2_Num);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
%Send_Basic_Parameter( hObject, handles)

% --- Executes on button press in radiobuttonTx2.
function radiobuttonTx2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonTx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobuttonTx2
Transmitter = get(handles.TransmitterSet,'SelectedObject');  
handles.ActiveTransmitterString=Transmitter.String;
handles.ActiveTxValue=2;
handles.ActiveNum_Tx=1;
set(findall(handles.radiobuttonDTx1, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDTx2, '-property', 'enable'), 'enable', 'on');
set(handles.radiobuttonDTx1, 'value', 0);
set(handles.radiobuttonDTx2, 'value', 1);
handles.ActiveDisplayChannelTx='Tx2';

LocalActiveTxValue=handles.ActiveTxValue;
Tx_Output=hex2dec('E400')+LocalActiveTxValue;
ForwardData=zeros(1024,1)+ Tx_Output;
Tx_instruction = uint16(ForwardData);
OutLength=miniradarputdata(Tx_instruction,handles.EndPoint2_Num);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
%Send_Basic_Parameter( hObject, handles)

% --- Executes on button press in radiobuttonTx12.
function radiobuttonTx12_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonTx12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Transmitter = get(handles.TransmitterSet,'SelectedObject');  
handles.ActiveTransmitterString=Transmitter.String;
handles.ActiveTxValue=3;
handles.ActiveNum_Tx=2;
set(findall(handles.radiobuttonDTx1, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDTx2, '-property', 'enable'), 'enable', 'on');
set(handles.radiobuttonDTx1, 'value', 1);
set(handles.radiobuttonDTx2, 'value', 0);
handles.ActiveDisplayChannelTx='Tx1';

LocalActiveTxValue=handles.ActiveTxValue;
Tx_Output=hex2dec('E400')+LocalActiveTxValue;
ForwardData=zeros(1024,1)+ Tx_Output;
Tx_instruction = uint16(ForwardData);
OutLength=miniradarputdata(Tx_instruction,handles.EndPoint2_Num);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
%SetActiveParameters(hObject, handles);

% --- Executes on button press in radiobuttonRx1.
function radiobuttonRx1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
handles.ActiveRxValue=1;
handles.ActiveNum_Rx=1;
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'off');
set(handles.radiobuttonDRx1, 'value', 1);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 0);


handles.ActiveDisplayChannelRx='Rx1';
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
    switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;  %base Sampling Number for 0.5ms
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 2  %1ms
            handles.ActiveSweepTime=1e-3;
            handles.BASN = 2048;%base Sampling Number for 1ms
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 3  %2ms
            handles.ActiveSweepTime=2e-3;
            handles.BASN = 4096;%base Sampling Number for 2ms
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
            set(handles.SamplingNumber, 'Value', 4);
            handles.ActiveSamplingNumber = 256;
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;
            handles.BASN = 8192;%base Sampling Number for 4ms
            handles.SN_Selections =  [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;
            handles.BASN = 16384; %base Sampling Number for 8ms
            handles.SN_Selections =[16384, 8192, 4096, 2048];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
    end
        

set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
%SetActiveParameters(hObject, handles);


% --- Executes on button press in radiobuttonRx2.
function radiobuttonRx2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
handles.ActiveRxValue=2;
handles.ActiveNum_Rx=1;
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'off');
set(handles.radiobuttonDRx1, 'value', 0);
set(handles.radiobuttonDRx2, 'value', 1);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 0);
handles.ActiveDisplayChannelRx='Rx2';
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
    switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;  %base Sampling Number for 0.5ms
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 2  %1ms
            handles.ActiveSweepTime=1e-3;
            handles.BASN = 2048;%base Sampling Number for 1ms
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 3  %2ms
            handles.ActiveSweepTime=2e-3;
            handles.BASN = 4096;%base Sampling Number for 2ms
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
            set(handles.SamplingNumber, 'Value', 4);
            handles.ActiveSamplingNumber = 256;
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;
            handles.BASN = 8192;%base Sampling Number for 4ms
            handles.SN_Selections =  [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;
            handles.BASN = 16384; %base Sampling Number for 8ms
            handles.SN_Selections =[16384, 8192, 4096, 2048];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
    end
        
set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
%SetActiveParameters(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonRx2

% --- Executes on button press in radiobuttonRx3.
function radiobuttonRx3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
handles.ActiveRxValue=4;
handles.ActiveNum_Rx=1;
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'off');
set(handles.radiobuttonDRx1, 'value', 0);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 1);
set(handles.radiobuttonDRx4, 'value', 0);
handles.ActiveDisplayChannelRx='Rx3';
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
    switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;  %base Sampling Number for 0.5ms
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 2  %1ms
            handles.ActiveSweepTime=1e-3;
            handles.BASN = 2048;%base Sampling Number for 1ms
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 3  %2ms
            handles.ActiveSweepTime=2e-3;
            handles.BASN = 4096;%base Sampling Number for 2ms
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
            set(handles.SamplingNumber, 'Value', 4);
            handles.ActiveSamplingNumber = 256;
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;
            handles.BASN = 8192;%base Sampling Number for 4ms
            handles.SN_Selections =  [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;
            handles.BASN = 16384; %base Sampling Number for 8ms
            handles.SN_Selections =[16384, 8192, 4096, 2048];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
    end
set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
%SetActiveParameters(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonRx3



% --- Executes on button press in radiobuttonRx4.
function radiobuttonRx4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
handles.ActiveRxValue=8;
handles.ActiveNum_Rx=1;
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'on');
set(handles.radiobuttonDRx1, 'value', 0);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 1);
handles.ActiveDisplayChannelRx='Rx4';
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
    switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;  %base Sampling Number for 0.5ms
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 2  %1ms
            handles.ActiveSweepTime=1e-3;
            handles.BASN = 2048;%base Sampling Number for 1ms
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 3  %2ms
            handles.ActiveSweepTime=2e-3;
            handles.BASN = 4096;%base Sampling Number for 2ms
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
            set(handles.SamplingNumber, 'Value', 4);
            handles.ActiveSamplingNumber = 256;
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;
            handles.BASN = 8192;%base Sampling Number for 4ms
            handles.SN_Selections =  [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;
            handles.BASN = 16384; %base Sampling Number for 8ms
            handles.SN_Selections =[16384, 8192, 4096, 2048];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
    end
    
set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonRx4


% --- Executes on button press in radiobuttonRx12.
function radiobuttonRx12_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
handles.ActiveRxValue=3;
handles.ActiveNum_Rx=2;
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
set(handles.radiobuttonDRx1, 'value', 1);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 0);
handles.ActiveDisplayChannelRx='Rx1';
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
    switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 512;    %base SamplinNumber=512, half for Num_Rx=2
            handles.SN_Selections = [512, 256, 128, 64];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);  %tag: SamplinNumber
       
        case 2  %1ms
            handles.ActiveSweepTime=1e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;   %base SamplinNumber=1024, half for Num_Rx=2
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
 
        case 3  %2ms
            handles.ActiveSweepTime=2e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 2048; %base SamplinNumber=2048, half for Num_Rx=2
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
          
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 4096;
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 8192;  %base SamplinNumber=8192, half for Num_Rx=2
            handles.SN_Selections = [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
    end
    
set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
%SetActiveParameters(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonRx12



% --- Executes on button press in radiobuttonRx34.
function radiobuttonRx34_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
handles.ActiveRxValue=12;
handles.ActiveNum_Rx=2;
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
set(handles.radiobuttonDRx1, 'value', 0);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 1);
set(handles.radiobuttonDRx4, 'value', 0);
handles.ActiveDisplayChannelRx='Rx1';
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
    switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 512;    %base SamplinNumber=512, half for Num_Rx=2
            handles.SN_Selections = [512, 256, 128, 64];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);  %tag: SamplinNumber
       
        case 2  %1ms
            handles.ActiveSweepTime=1e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;   %base SamplinNumber=1024, half for Num_Rx=2
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
 
        case 3  %2ms
            handles.ActiveSweepTime=2e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 2048; %base SamplinNumber=2048, half for Num_Rx=2
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
          
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 4096;
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 8192;  %base SamplinNumber=8192, half for Num_Rx=2
            handles.SN_Selections = [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
    end
    
set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonRx34


% --- Executes on button press in radiobuttonRxAll.
function radiobuttonRxAll_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRxAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
handles.ActiveRxValue=15;
handles.ActiveNum_Rx=4;
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
set(handles.radiobuttonDRx1, 'value', 1);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 0);
handles.ActiveDisplayChannelRx='Rx1';
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value'); 
LASTV=handles.ActiveSweepTimeValue;
    switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN =256;    %base SamplinNumber=512, half for Num_Rx=2
            handles.SN_Selections = [256, 128, 64, 32];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);  %tag: SamplinNumber
       
        case 2  %1ms
            handles.ActiveSweepTime=1e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 512;   %base SamplinNumber=1024, half for Num_Rx=2
            handles.SN_Selections = [512, 256, 128, 64];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
 
        case 3  %2ms
            handles.ActiveSweepTime=2e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024; %base SamplinNumber=2048, half for Num_Rx=2
            handles.SN_Selections =  [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
          
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 2048;
            handles.SN_Selections = [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 4096;  %base SamplinNumber=8192, half for Num_Rx=2
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
  
    end
    
set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonRxAll



% --- Executes on button press in radiobuttonSawtooth.
function radiobuttonSawtooth_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSawtooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Update handles before use function 'Send_PLL_Sawtooth' 

set(findall(handles.FrequencyHigh, '-property', 'enable'), 'enable', 'on');
Modulation = get(handles.ModulationSet,'SelectedObject'); 
handles.ActiveModulationString=Modulation.String;
handles.ActiveModulationValue=0;
LAMV_Output=hex2dec('E100')+0;
ForwardData=zeros(1024,1)+ LAMV_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
%LAMV_Output_h=dec2hex(LAMV_Output);
%handles.NewWaterfall=1;
guidata(hObject, handles);

% --- Executes on button press in radiobuttonCW.
function radiobuttonCW_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonCW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.FrequencyHigh,'Value',9); 
handles.ActiveFrequencyHighValue=9;
set(findall(handles.FrequencyHigh, '-property', 'enable'), 'enable', 'off');

Modulation = get(handles.ModulationSet,'SelectedObject'); 
handles.ActiveModulationString=Modulation.String;
handles.ActiveModulationValue=3;
LAMV_Output=hex2dec('E100')+3;
ForwardData=zeros(1024,1)+ LAMV_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
%LAMV_Output_h=dec2hex(LAMV_Output);
handles.NewWaterfall=1;
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonCW


% --- Executes on button press in radiobutton10s.
function radiobutton10s_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton10s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveRecordTime=10;
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobutton10s

% --- Executes on button press in radiobutton30s.
function radiobutton30s_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton30s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveRecordTime=30;
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobutton30s

% --- Executes on button press in radiobutton60s.
function radiobutton60s_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton60s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveRecordTime=60;
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobutton60s

% --- Executes on button press in radiobutton120s.
function radiobutton120s_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton120s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveRecordTime=120;
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobutton120s


% --- Executes on button press in radiobutton120s.
function radiobuttonDRx1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton120s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveDisplayChannelRx='Rx1';
set(handles.radiobuttonDRx1, 'value', 1);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 0);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
[handles]=SetActiveParameters(hObject, handles);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonDRx1

% --- Executes on button press in radiobuttonDRx2.
function radiobuttonDRx2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDRx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveDisplayChannelRx='Rx2';
set(handles.radiobuttonDRx1, 'value', 0);
set(handles.radiobuttonDRx2, 'value', 1);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 0);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
[handles]=SetActiveParameters(hObject, handles);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonDRx2

% --- Executes on button press in radiobuttonDRx3.
function radiobuttonDRx3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDRx3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveDisplayChannelRx='Rx3';
set(handles.radiobuttonDRx1, 'value', 0);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 1);
set(handles.radiobuttonDRx4, 'value', 0);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
[handles]=SetActiveParameters(hObject, handles);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonDRx3


% --- Executes on button press in radiobuttonDRx4.
function radiobuttonDRx4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDRx4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveDisplayChannelRx='Rx4';
set(handles.radiobuttonDRx1, 'value', 0);
set(handles.radiobuttonDRx2, 'value', 0);
set(handles.radiobuttonDRx3, 'value', 0);
set(handles.radiobuttonDRx4, 'value', 1);
guidata(hObject, handles);
% send MD,ST,SN,Tx,Rx parameters to MCU,
[handles]=SetActiveParameters(hObject, handles);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonDRx4


% --- Executes on slider movement.
function DynamicRangeLowSet_Callback(hObject, eventdata, handles)
% hObject    handle to DynamicRangeLowSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveDynamicRangeLow= get(hObject,'Value');
if handles.ActiveDynamicRangeLow>=handles.ActiveDynamicRangeHigh
    handles.ActiveDynamicRangeLow=handles.ActiveDynamicRangeHigh-0.1;
%    handles.ActiveDynamicRangeHigh=5;
%    set(handles.DynamicRangeHighSet, 'Value', 3);
    set(handles.DynamicRangeLowSet, 'Value', handles.ActiveDynamicRangeHigh-0.1);
end
guidata(hObject, handles);

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% --- Executes on slider movement.
function DynamicRangeHighSet_Callback(hObject, eventdata, handles)
% hObject    handle to DynamicRangeHighSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ActiveDynamicRangeHigh= get(hObject,'Value');
if handles.ActiveDynamicRangeHigh<=handles.ActiveDynamicRangeLow+0.1
    handles.ActiveDynamicRangeHigh=handles.ActiveDynamicRangeLow+0.1;
%   handles.ActiveDynamicRangeLow=4;
    set(handles.DynamicRangeHighSet, 'Value', handles.ActiveDynamicRangeLow+0.1);
%  set(handles.DynamicRangeLowSet, 'Value', 2.5);
end
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function radiobuttonTx1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonTx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonTx2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonTx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonTx12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonTx12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonRx1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonRx2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonRx3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function radiobuttonSawtooth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonSawtooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonCW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonCW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function radiobutton10s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton10s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function radiobutton30s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton30s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function radiobutton60s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton60s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobutton120s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton120s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function pushbuttonRefresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonRefresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function radiobuttonDRx1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonDRx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function radiobuttonDRx2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonDRx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function DynamicRangeLowSet_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DynamicRangeLowSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function DynamicRangeHighSet_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DynamicRangeHighSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


    
% --- Executes on button press in pushbuttonRecord.
function pushbuttonRecord_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRecord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% set(findall(handles.OperationPanel, '-property', 'enable'), 'enable', 'on');
% set(findall(handles.ParameterPanel, '-property', 'enable'), 'enable', 'off');
% set(findall(handles.ChannelPanel, '-property', 'enable'), 'enable', 'off');
% set(findall(handles.TransmitterSet, '-property', 'enable'), 'enable', 'off');
% set(findall(handles.ReceiverSet, '-property', 'enable'), 'enable', 'off');
% set(findall(handles.DisplayPanel, '-property', 'enable'), 'enable', 'off'); 
% set(findall(handles.DynamicRangePanel, '-property', 'enable'), 'enable', 'off');
% set(findall(handles.RecorderPanel, '-property', 'enable'), 'enable', 'off');
% set(findall(handles.WaveformPanel, '-property', 'enable'), 'enable', 'off'); 
% set(findall(handles.RangeProfilePanel, '-property', 'enable'), 'enable', 'off'); 
% set(findall(handles.RangeVelocityPanel, '-property', 'enable'), 'enable', 'off'); 
% set(findall(handles.RecordTimeSet, '-property', 'enable'), 'enable', 'off'); 
guidata(hObject, handles);
Send_Basic_Parameter( hObject, handles);

%Send PLL registry parameters to MCU  
LAMS=handles.ActiveModulationString; %LocalActiveModulation 
LAMSV=handles.ActiveModulationValue; 

LART=handles.ActiveRecordTime;   
LAST=handles.ActiveSweepTime;  
LAFL=handles.ActiveFrequencyLow;
LAFH=handles.ActiveFrequencyHigh; 
LASNV=handles.ActiveSamplingNumberValue ;    
LASN=handles.SN_Selections(LASNV);
LANR=handles.ActiveNum_Rx;
LANT=handles.ActiveNum_Tx;  
LATS=handles.ActiveTransmitterString;
LARS=handles.ActiveReceiverString;
NumSweeps = LART / LAST; 
handles.NumSweeps=NumSweeps;
guidata(hObject, handles);
%Send PLL registry parameters to MCU  
if strcmp(LAMS,'Sawtooth')
    handles.ActiveModulationValue=0;
    [handles]=Send_PLL_Sawtooth( hObject, handles);
end
if strcmp(LAMS,'CW')
    handles.ActiveModulationValue=3;
    [handles]=Send_PLL_CW( hObject, handles);
end

[ComplexDataTx1, ComplexDataTx2, NumSweeps] = GetComplexData( handles);
% Prompt window
 DATE = datestr(now);
% DATEVECTOR = datevec(DATE);
% filename = sprintf('PUP%2.f_%2.f_%2.f_%2.f_%2.f_%2.f', DATEVECTOR(1), DATEVECTOR(2), DATEVECTOR(3), DATEVECTOR(4), DATEVECTOR(5), DATEVECTOR(6));
 DATEF = datestr(now,30);
 filename=['PUP',DATEF];
% DateVector = datevec(DATE);
% filename = sprintf('PUP%4.f', DateVector(1));

[file, path] = uiputfile({'.mat';'.txt'},'Save file name',filename);
filename = [path, file];
if file == 0
    % Reset display_uibuttongroup, dynamic_range_uibuttongroup, and waterall_uibuttongroup
    % waveform_SelectionChangedFcn(hObject, eventdata, handles);
    set(handles.MessageWindow,'String', handles.model,'ForegroundColor','green');
    return
end
    if strcmp(LAMS,'Sawtooth')
        if strcmp(file(end-3:end), '.mat')
            if (LANT==1 & LATS=='Tx1')
                
                save(filename, 'DATE','LAMS','LAFL','LAFH','LAST','LASN','ComplexDataTx1', ...
                                'LARS', 'LATS', 'LANR', 'LANT');
            elseif (LANT==1 & LATS=='Tx2')
                save(filename, 'DATE','LAMS','LAFL','LAFH','LAST','LASN','ComplexDataTx2', ...
                                'LARS', 'LATS', 'LANR', 'LANT');   
            else
                save(filename, 'DATE','LAMS','LAFL','LAFH','LAST','LASN','ComplexDataTx1','ComplexDataTx2', ... 
                                'LARS', 'LATS', 'LANR', 'LANT');       
            end
        else
            fID = fopen(filename,'w'); 
            fprintf(fID, '%d\n', DATE);
            fprintf(fID, '%d\n', LAMS);               
            fprintf(fID, '%d\n', LARS);
            fprintf(fID, '%d\n', LATS);
            fprintf(fID, '%d\n', LAFL);
            fprintf(fID, '%d\n', LAFH);
            fprintf(fID, '%d\n', LAST);
            fprintf(fID, '%d\n', LASN);
            fprintf(fID, '%d\n', LART);
            fprintf(fID, '%d\n', LANT);    
            if (LANT==1 & LATS=='Tx1')
                fprintf(fID, '%d\n', ComplexDataTx1);
            elseif (LANT==1 & LATS=='Tx2')
                fprintf(fID, '%d\n', ComplexDataTx2);  
            else
                fprintf(fID, '%d\n', ComplexDataTx1);
                fprintf(fID, '%d\n', ComplexDataTx2); 
            end
            fclose(fID);
        end
    elseif strcmp(LAMS,'CW')
        if strcmp(file(end-3:end), '.mat')
            if (LANT==1 & LATS=='Tx1')
                
                save(filename, 'DATE','LAMS','LAFL','LAFH','LAST','LASN','ComplexDataTx1', ...
                                'LARS', 'LATS', 'LANR', 'LANT');
            elseif (LANT==1 & LATS=='Tx2')
                save(filename, 'DATE','LAMS','LAFL','LAFH','LAST','LASN','ComplexDataTx2', ...
                                'LARS', 'LATS', 'LANR', 'LANT');   
            else
                save(filename, 'DATE','LAMS','LAFL','LAFH','LAST','LASN','ComplexDataTx1','ComplexDataTx2', ... 
                                'LARS', 'LATS', 'LANR', 'LANT');       
            end
        else
            fID = fopen(filename,'w');
            fprintf(fID, '%d\n', DATE);
            fprintf(fID, '%d\n', LAMS);            
            fprintf(fID, '%d\n', LARS);
            fprintf(fID, '%d\n', LATS);
            fprintf(fID, '%d\n', LAFL);
            fprintf(fID, '%d\n', LAST);
            fprintf(fID, '%d\n', LASN);
            fprintf(fID, '%d\n', LART);
            fprintf(fID, '%d\n', LANT);            
            if (LANT==1 & LATS=='Tx1')
                fprintf(fID, '%d\n', ComplexDataTx1);
            elseif (LANT==1 & LATS=='Tx2')
                fprintf(fID, '%d\n', ComplexDataTx2);  
            else
                fprintf(fID, '%d\n', ComplexDataTx1);
                fprintf(fID, '%d\n', ComplexDataTx2); 
            end    
            fclose(fID);
        end     
    end
% Reset display_uibuttongroup, dynamic_range_uibuttongroup, and waterfall_uibuttongroup
% waveform_SelectionChangedFcn(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function pushbuttonRecord_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonRecord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function togglebuttonStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to togglebuttonStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% % --- Executes when user attempts to close SDR.
% function PUP_CloseRequestFcn(hObject, eventdata, handles)
% % hObject    handle to PUP (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: delete(hObject) closes the figure
% 
% infoFig= findall(0, 'Name', 'MessageWindow');
% if ~isempty(infoFig)
%     delete(infoFig)
% end
% pause(.2);
% 
% hObject = findall(0,'tag','PUPradarGUI');
% delete(hObject);

% --- Update Active parameters to handles.
function [newhandles]=SetActiveParameters(hObject, handles)
%Set Active Transmitter
Transmitter = get(handles.TransmitterSet,'SelectedObject');  
handles.ActiveTransmitterString=Transmitter.String;
if handles.modelcode==240140201
    handles.ActiveTxValue=1;
    handles.ActiveNum_Tx=1;
    set(findall(handles.radiobuttonTx1, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonTx2, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonTx12, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDTx1, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDTx2, '-property', 'enable'), 'enable', 'off');    
    set(handles.radiobuttonTx1, 'value', 1);
    set(handles.radiobuttonTx2, 'value', 0);  
    set(handles.radiobuttonTx12, 'value', 0);  
    set(handles.radiobuttonDTx1, 'value', 1);
    set(handles.radiobuttonDTx2, 'value', 0); 
else
    if strcmp(handles.ActiveTransmitterString,'Tx1')
        handles.ActiveTxValue=1;
        handles.ActiveNum_Tx=1;
        set(findall(handles.radiobuttonDTx1, '-property', 'enable'), 'enable', 'on');
        set(findall(handles.radiobuttonDTx2, '-property', 'enable'), 'enable', 'off');
        set(handles.radiobuttonDTx1, 'value', 1);
        set(handles.radiobuttonDTx2, 'value', 0); 
    elseif strcmp(handles.ActiveTransmitterString,'Tx2')
        handles.ActiveTxValue=2;
        handles.ActiveNum_Tx=1;
        set(findall(handles.radiobuttonDTx1, '-property', 'enable'), 'enable', 'off');
        set(findall(handles.radiobuttonDTx2, '-property', 'enable'), 'enable', 'on');
        set(handles.radiobuttonDTx1, 'value', 0);
        set(handles.radiobuttonDTx2, 'value', 1); 
    elseif strcmp(handles.ActiveTransmitterString, 'Tx1.Tx2')
        handles.ActiveTxValue=3;
        handles.ActiveNum_Tx=2;
        set(findall(handles.radiobuttonDTx1, '-property', 'enable'), 'enable', 'on');
        set(findall(handles.radiobuttonDTx2, '-property', 'enable'), 'enable', 'on');
    %     set(handles.radiobuttonDTx1, 'value', 1);
    %     set(handles.radiobuttonDTx2, 'value', 0); 
    end
end
%Set Active Receiver 
Receiver = get(handles.ReceiverSet,'SelectedObject'); 
handles.ActiveReceiverString=Receiver.String;
if strcmp(handles.ActiveReceiverString,'Rx1')
    handles.ActiveRxValue=1;
    handles.ActiveNum_Rx=1;
    set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'off');         
elseif strcmp(handles.ActiveReceiverString,'Rx2')
    handles.ActiveRxValue=2;
    handles.ActiveNum_Rx=1;
    set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'off');            
elseif strcmp(handles.ActiveReceiverString,'Rx3')
    handles.ActiveRxValue=4;
    handles.ActiveNum_Rx=1;
    set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'off');        
elseif strcmp(handles.ActiveReceiverString,'Rx4')
    handles.ActiveRxValue=8;
    handles.ActiveNum_Rx=1;
    set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'on');        
%     set(handles.radiobuttonDRx1, 'value', 0);
%     set(handles.radiobuttonDRx2, 'value', 0);     
%     set(handles.radiobuttonDRx3, 'value', 0);
%     set(handles.radiobuttonDRx4, 'value', 1);    
elseif strcmp(handles.ActiveReceiverString,'Rx1.Rx2')
    handles.ActiveRxValue=3;
    handles.ActiveNum_Rx=2;
    set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'off');              
elseif strcmp(handles.ActiveReceiverString,'Rx3.Rx4')
    handles.ActiveRxValue=12;
    handles.ActiveNum_Rx=2;
    set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'on');            
elseif strcmp(handles.ActiveReceiverString, 'All')
    handles.ActiveRxValue=15;    
    handles.ActiveNum_Rx=4;
    set(findall(handles.radiobuttonDRx1, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx2, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx3, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.radiobuttonDRx4, '-property', 'enable'), 'enable', 'on');        
%     set(handles.radiobuttonDRx1, 'value', 1);
%     set(handles.radiobuttonDRx2, 'value', 0);     
%     set(handles.radiobuttonDRx3, 'value', 0);
%     set(handles.radiobuttonDRx4, 'value', 0);     
%     set(handles.radiobuttonDRx1, 'value', 1);
%     set(handles.radiobuttonDRx2, 'value', 0); 
end
%Set Active Modulation
Modulation = get(handles.ModulationSet,'SelectedObject'); 
handles.ActiveModulationString=Modulation.String;
LAMS=handles.ActiveModulationString; %LocalActiveModulation    
if strcmp(LAMS,'Sawtooth')
    handles.ActiveModulationValue=0;
end
if strcmp(LAMS,'CW')
    handles.ActiveModulationValue=3;
end

% Set Active FrequencyHigh
handles.ActiveFrequencyHighValue= get(handles.FrequencyHigh,'Value');
switch handles.ActiveFrequencyHighValue 
    case 1
        handles.ActiveFrequencyHigh=24.0e9;  
    case 2
        handles.ActiveFrequencyHigh=24.25e9;               
    case 3
        handles.ActiveFrequencyHigh=24.5e9;
    case 4
        handles.ActiveFrequencyHigh=24.75e9;
    case 5                
        handles.ActiveFrequencyHigh=25.0e9;
    case 6                
        handles.ActiveFrequencyHigh=25.25e9;                
    case 7                
        handles.ActiveFrequencyHigh=25.5e9;
    case 8                
        handles.ActiveFrequencyHigh=25.75e9;
    case 9        
        handles.ActiveFrequencyHigh=26.0e9;
end
%Set Active FrequencyLow
handles.ActiveFrequencyLowValue= get(handles.FrequencyLow,'Value');
switch handles.ActiveFrequencyLowValue  
    case 1
        handles.ActiveFrequencyLow=24.0e9;  
    case 2
        handles.ActiveFrequencyLow=24.25e9;               
    case 3
        handles.ActiveFrequencyLow=24.5e9;
    case 4
        handles.ActiveFrequencyLow=24.75e9;
    case 5                
        handles.ActiveFrequencyLow=25.0e9;
    case 6                
        handles.ActiveFrequencyLow=25.25e9;                
    case 7                
        handles.ActiveFrequencyLow=25.5e9;
    case 8                
        handles.ActiveFrequencyLow=25.75e9;
    case 9        
        handles.ActiveFrequencyLow=26.0e9;
end 


handles.ActiveBandwidth=handles.ActiveFrequencyHigh-handles.ActiveFrequencyLow;
% set Active Sweep Time and Active Sampling Number        
handles.ActiveSweepTimeValue= get(handles.SweepTime,'Value');
handles.ActiveSamplingNumberValue= get(handles.SamplingNumber,'Value');
SAMPLINnumber=get(handles.SamplingNumber,'Value')
LASTV=handles.ActiveSweepTimeValue;

switch handles.ActiveNum_Rx
    case 1
        switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;  %base Sampling Number for 0.5ms
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 2  %1ms
            handles.ActiveSweepTime=1e-3;
            handles.BASN = 2048;%base Sampling Number for 1ms
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 3  %2ms
            handles.ActiveSweepTime=2e-3;
            handles.BASN = 4096;%base Sampling Number for 2ms
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
            set(handles.SamplingNumber, 'Value', 4);
            handles.ActiveSamplingNumber = 256;
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;
            handles.BASN = 8192;%base Sampling Number for 4ms
            handles.SN_Selections =  [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;
            handles.BASN = 16384; %base Sampling Number for 8ms
            handles.SN_Selections =[16384, 8192, 4096, 2048];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
        end
    
    case 2
        switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 512;    %base SamplinNumber=512, half for Num_Rx=2
            handles.SN_Selections = [512, 256, 128, 64];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);  %tag: SamplinNumber
       
        case 2  %1ms
            handles.ActiveSweepTime=1e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024;   %base SamplinNumber=1024, half for Num_Rx=2
            handles.SN_Selections = [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
 
        case 3  %2ms
            handles.ActiveSweepTime=2e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 2048; %base SamplinNumber=2048, half for Num_Rx=2
            handles.SN_Selections =  [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
          
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 4096;
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 8192;  %base SamplinNumber=8192, half for Num_Rx=2
            handles.SN_Selections = [8192, 4096, 2048, 1024];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
        end 
        
    case 4
        switch LASTV
        case 1  %500us
            handles.ActiveSweepTime=0.5e-3;          %LAST: LocalActiveSweepTime
            handles.BASN =256;    %base SamplinNumber=512, half for Num_Rx=2
            handles.SN_Selections = [256, 128, 64, 32];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);  %tag: SamplinNumber
       
        case 2  %1ms
            handles.ActiveSweepTime=1e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 512;   %base SamplinNumber=1024, half for Num_Rx=2
            handles.SN_Selections = [512, 256, 128, 64];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
 
        case 3  %2ms
            handles.ActiveSweepTime=2e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 1024; %base SamplinNumber=2048, half for Num_Rx=2
            handles.SN_Selections =  [1024, 512, 256, 128];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
          
        case 4  %4ms
            handles.ActiveSweepTime=4e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 2048;
            handles.SN_Selections = [2048, 1024, 512, 256];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);

        case 5  %8ms
            handles.ActiveSweepTime=8e-3;          %LAST: LocalActiveSweepTime
            handles.BASN = 4096;  %base SamplinNumber=8192, half for Num_Rx=2
            handles.SN_Selections = [4096, 2048, 1024, 512];
            set(handles.SamplingNumber, 'String', handles.SN_Selections);
  
        end
    
end
set(handles.SamplingNumber, 'Value', handles.ActiveSamplingNumberValue);
% set Active Diplay channels            
DisplayChannelRx = get(handles.DisplayRx,'SelectedObject') ;        
handles.ActiveDisplayChannelRx=DisplayChannelRx.String;
DisplayChannelTx = get(handles.DisplayTx,'SelectedObject') ;        
handles.ActiveDisplayChannelTx=DisplayChannelTx.String;

% set Active Dynamic Range Low            
handles.ActiveDynamicRangeLow= get(handles.DynamicRangeLowSet,'Value');          
            
% set Active Dynamic Range High               
handles.ActiveDynamicRangeHigh= get(handles.DynamicRangeHighSet,'Value');

% set Active Record Time            
ActiveRecordTimeSet = get(handles.RecordTimeSet,'SelectedObject') ;        
handles.ActiveRecordTimeString=ActiveRecordTimeSet.String;
LARTS=ActiveRecordTimeSet.String;

switch LARTS
    case '10s'
     handles.ActiveRecordTime=10; 
    case '30s'
     handles.ActiveRecordTime=30;  
    case '60s'
     handles.ActiveRecordTime=60;  
    case '120s'
     handles.ActiveRecordTime=120;  
end

% Choose default command line output for PUPradarGUI
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
newhandles=handles;

% ---  send MD,ST,SN,Tx,Rx parameters to MCU,.
function Send_Basic_Parameter(hObject, handles)
%Send Modulation parameter
Modulation = get(handles.ModulationSet,'SelectedObject'); 
handles.ActiveModulationString=Modulation.String;

LocalActiveModulationValue=handles.ActiveModulationValue;
LAMV_Output=hex2dec('E100')+LocalActiveModulationValue;
ForwardData=zeros(1024,1)+ LAMV_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
LAMV_Output_h=dec2hex(LAMV_Output);

% Send Sweeptime Parameter information
LASTV=handles.ActiveSweepTimeValue;
LASTV_Output=hex2dec('E200')+LASTV;
ForwardData=zeros(1024,1)+ LASTV_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
LASTV_Output_h=dec2hex(LASTV_Output);

%Send Sampling Number
LASNV=handles.ActiveSamplingNumberValue;
LASNV_Output=hex2dec('E300')+LASNV;
ForwardData=zeros(1024,1)+ LASNV_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
LASNV_Output_h=dec2hex(LASNV_Output);

%Send Tx information
LocalActiveTxValue=handles.ActiveTxValue;
Tx_Output=hex2dec('E400')+LocalActiveTxValue;
ForwardData=zeros(1024,1)+ Tx_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
Tx_Output_h=dec2hex(Tx_Output);

%Send Rx information
LocalActiveRxValue=handles.ActiveRxValue;
Rx_Output=hex2dec('E500')+LocalActiveRxValue;
ForwardData=zeros(1024,1)+ Rx_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData, handles.EndPoint2_Num);
Rx_Output_h=dec2hex(Rx_Output);

%Send PLL registry parameters to MCU


%Send PLL registry CW parameters to MCU
function [Newhandles]=Send_PLL_CW(hObject, handles)
LAFL=handles.ActiveFrequencyLow;

% for BGT24, F_PLLinput = F_Tx/16, others, may F_PLLinput = F_Tx/2
F_start = LAFL / 16;

Start_N = F_start / 50e6;
Start_N_int = floor(Start_N);
Start_N_frac = Start_N - Start_N_int;
PLLReg03 = Start_N_int; 
PLLReg03_h = dec2hex(Start_N_int) ;
PLLReg04 = round(Start_N_frac * 2^24);
Low8bit=mod(PLLReg03,2^8);
PLL03L_Output=hex2dec('C300')+Low8bit;
%PLL03L_h=dec2hex(PLL03L_Output);

ForwardData=zeros(1024,1)+ PLL03L_Output;
SendOutData = uint16(ForwardData);
SendOut1=SendOutData
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Middle8bit=mod(PLLReg03-Low8bit,2^16)/2^8;
PLL03M_Output=hex2dec('C200')+Middle8bit;
%PLL03M_h=dec2hex(PLL03M_Output);
%SendOut2=PLL03M_h;
ForwardData=zeros(1024,1)+ PLL03M_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=(PLLReg03-Low8bit-Middle8bit*2^8)/2^16;
PLL03H_Output=hex2dec('C100')+High8bit;
% PLL03H_h=dec2hex(PLL03H_Output);
% SendOut3=PLL03H_h;
ForwardData=zeros(1024,1)+ PLL03H_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Low8bit=mod(PLLReg04,2^8);
PLL04L_Output=hex2dec('C600')+Low8bit;
% PLL04L_h=dec2hex(PLL04L_Output);
% SendOut4=PLL04L_h;
ForwardData=zeros(1024,1)+ PLL04L_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Middle8bit=mod(PLLReg04-Low8bit,2^16)/2^8;
PLL04M_Output=hex2dec('C500')+Middle8bit;
% PLL04M_h=dec2hex(PLL04M_Output);
% SendOut5=PLL04M_h;
ForwardData=zeros(1024,1)+ PLL04M_Output;
SendOutData = uint16(ForwardData);

OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=(PLLReg04-Low8bit-Middle8bit*2^8)/2^16;
PLL04H_Output=hex2dec('C400')+High8bit;
% PLL04H_h=dec2hex(PLL04H_Output);
% SendOut6=PLL04H_h;
ForwardData=zeros(1024,1)+ PLL04H_Output;
SendOutData = uint16(ForwardData);
SendOutData6=SendOutData
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
[Newhandles]=handles;
% Update handles
guidata(hObject, handles);


%Send PLL registry Sawtooth parameters to MCU
function [Newhandles]=Send_PLL_Sawtooth(hObject, handles)

LAFL=handles.ActiveFrequencyLow;
LAFH=handles.ActiveFrequencyHigh;
LAST=handles.ActiveSweepTime;

T_ref  = 1/50e6;    % T_ref=1/F_ref=1/50MHz

handles.ActiveBandwidth=LAFH-LAFL;   
LABW=handles.ActiveBandwidth;           % LABW=LocalActiveBandwidth
if LABW<=0.5e9
    T_Sweepup_Percent=0.94;  % for BW<=500MHz ;
elseif LABW==1e9
    T_Sweepup_Percent=0.92;  % for BW=1GHz 
elseif LABW==1.5e9
    T_Sweepup_Percent=0.84;   % for BW=1.5GHz 
elseif LABW==2e9
    T_Sweepup_Percent=0.8;   % for BW=2GHz   
else
    T_Sweepup_Percent=0.75;   % for BW>2GHz   
end
switch LAST  %Local Active Sweep Time
  case 0.5e-3
    MaxSweepover = 4096; %4096steps
  case 1e-3
    MaxSweepover = 8192; %8192steps
  case 2e-3
    MaxSweepover = 16384;
  case 4e-3 
    MaxSweepover = 32768;
  case 8e-3
    MaxSweepover = 65536;
end


handles.ActivePLLSweepStop=ceil(MaxSweepover*(T_Sweepup_Percent+0.01));
LocalActivePLLSweepStop=handles.ActivePLLSweepStop;
T_Sweepup = LAST*T_Sweepup_Percent;
%%% Send PLLSweepStop, it is 16 bits long
Low8bit=mod(LocalActivePLLSweepStop,2^8);
PLLSweepStopL_Output=hex2dec('D200')+Low8bit;
%
PLLSweepStopL_h=dec2hex(PLLSweepStopL_Output);
ForwardData=zeros(1024,1)+ PLLSweepStopL_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=mod(LocalActivePLLSweepStop-Low8bit,2^16)/2^8;
PLLSweepStopH_Output=hex2dec('D100')+High8bit;
%
PLLSweepStopH_h=dec2hex(PLLSweepStopH_Output);
ForwardData=zeros(1024,1)+ PLLSweepStopH_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

% for BGT24, F_PLLinput = F_Tx/16, others, may F_PLLinput = F_Tx/2
F_start = LAFL / 16;
F_stop = LAFH / 16;

% Calculate PLL output value
Start_N = F_start / 50e6;       
Stop_N = F_stop / 50e6;
Start_N_int = floor(Start_N);
Start_N_frac = Start_N - Start_N_int;
Stop_N_int = floor(Stop_N);
% Stop_N_frac = Stop_N - Stop_N_int;
PLLReg03 = Start_N_int; 
PLLReg04 = round(Start_N_frac * 2^24);

Low8bit=mod(PLLReg03,2^8);
PLL03L_Output=hex2dec('C300')+Low8bit;
%PLL03L_h=dec2hex(PLL03L_Output);
ForwardData=zeros(1024,1)+ PLL03L_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Middle8bit=mod(PLLReg03-Low8bit,2^16)/2^8;
PLL03M_Output=hex2dec('C200')+Middle8bit;
%PPL03M_h=dec2hex(PLL03M_Output);
ForwardData=zeros(1024,1)+ PLL03M_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=(PLLReg03-Low8bit-Middle8bit*2^8)/2^16;
PLL03H_Output=hex2dec('C100')+High8bit;
%PLL03H_h=dec2hex(PLL03H_Output);
ForwardData=zeros(1024,1)+ PLL03H_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Low8bit=mod(PLLReg04,2^8);
PLL04L_Output=hex2dec('C600')+Low8bit;
%PLL04L_h=dec2hex(PLL04L_Output);
ForwardData=zeros(1024,1)+ PLL04L_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Middle8bit=mod(PLLReg04-Low8bit,2^16)/2^8;
PLL04M_Output=hex2dec('C500')+Middle8bit;
%PPL04M_h=dec2hex(PLL04M_Output);
ForwardData=zeros(1024,1)+ PLL04M_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=(PLLReg04-Low8bit-Middle8bit*2^8)/2^16;
PLL04H_Output=hex2dec('C400')+High8bit;
%PLL04H_h=dec2hex(PLL04H_Output);
ForwardData=zeros(1024,1)+ PLL04H_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

% estimated number of steps in T_sweepup
NumSteps = T_Sweepup / T_ref;

%  step size in number of 50MHz
Step_int = (Stop_N - Start_N) / NumSteps;
% Stop_N;
% Start_N;
%  step size in Number of minimum frequency 2.98Hz
Step_N = round(Step_int * 2^24);
PLLReg0A = Step_N;
Low8bit=mod(PLLReg0A,2^8);
PLL0AL_Output=hex2dec('C900')+Low8bit;
PLL0AL_h=dec2hex(PLL0AL_Output);
ForwardData=zeros(1024,1)+ PLL0AL_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Middle8bit=mod(PLLReg0A-Low8bit,2^16)/2^8;
PLL0AM_Output=hex2dec('C800')+Middle8bit;
PPL0AM_h=dec2hex(PLL0AM_Output);
ForwardData=zeros(1024,1)+ PLL0AM_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=(PLLReg0A-Low8bit-Middle8bit*2^8)/2^16;
PLL0AH_Output=hex2dec('C700')+High8bit;
PLL0AH_h=dec2hex(PLL0AH_Output);
ForwardData=zeros(1024,1)+ PLL0AH_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

% adjust to approach accurate stop frequency
NumSteps = round((Stop_N - Start_N)/(Step_N/2^24));

% Number steps in 50MHz
Num_of_50MHz = floor(NumSteps*Step_N/2^24);
PLLReg0C = Start_N_int + Num_of_50MHz;
PLLReg0D = mod(NumSteps*Step_N, 2^24) + PLLReg04;

if PLLReg0D > 2^24
    PLLReg0C = PLLReg0C + 1;
    PLLReg0D = PLLReg0D - 2^24;
end
Low8bit=mod(PLLReg0C,2^8);
PLL0CL_Output=hex2dec('CC00')+Low8bit;
PLL0CL_h=dec2hex(PLL0CL_Output);
ForwardData=zeros(1024,1)+ PLL0CL_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Middle8bit=mod(PLLReg0C-Low8bit,2^16)/2^8;
PLL0CM_Output=hex2dec('CB00')+Middle8bit;
PPL0CM_h=dec2hex(PLL0CM_Output);
ForwardData=zeros(1024,1)+ PLL0CM_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=(PLLReg0C-Low8bit-Middle8bit*2^8)/2^16;
PLL0CH_Output=hex2dec('CA00')+High8bit;
PLL0CH_h=dec2hex(PLL0CH_Output);
ForwardData=zeros(1024,1)+ PLL0CH_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Low8bit=mod(PLLReg0D,2^8);
PLL0DL_Output=hex2dec('CF00')+Low8bit;
PLL0DL_h=dec2hex(PLL0DL_Output);
ForwardData=zeros(1024,1)+ PLL0DL_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

Middle8bit=mod(PLLReg0D-Low8bit,2^16)/2^8;
PLL0DM_Output=hex2dec('CE00')+Middle8bit;
PPL0DM_h=dec2hex(PLL0DM_Output);
ForwardData=zeros(1024,1)+ PLL0DM_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);

High8bit=(PLLReg0D-Low8bit-Middle8bit*2^8)/2^16;
PLL0DH_Output=hex2dec('CD00')+High8bit;
PLL0DH_h=dec2hex(PLL0DH_Output);
ForwardData=zeros(1024,1)+ PLL0DH_Output;
SendOutData = uint16(ForwardData);
OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
[Newhandles]=handles;
% Update handles
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%==========================
%PUPradar initiation Function
function [Newhandles]=PUPradar_initiating(hObject, handles)  
    [device_count, vID, pID] = usbcheckchip;
    if (device_count > 1)
        set(handles.MessageWindow,'String','More than one USB board','ForegroundColor','red');
        return
    elseif device_count == 0
        set(handles.MessageWindow,'String','No USB board found','ForegroundColor','red');
        return
    end
    if (vID~=1204) || (pID~=34323)
        set(handles.MessageWindow,'String','Wrong USB chip','ForegroundColor','red');
        return
    end
    
     interface_no = usbsetinterface1;
    if interface_no~=1
        set(handles.message,'String','Set interface failure','ForegroundColor','Green');
        return
    end
    handles.EndPoint2_Num = usbfindendpoint(2);
    if handles.EndPoint2_Num == 0
        set(handles.message,'String','Could not find endpoint 2','ForegroundColor','red');
        return
    end
    handles.EndPoint6_Num = usbfindendpoint(134);
    if handles.EndPoint6_Num == 0
        set(handles.message,'String','Could not find endpoint 6','ForegroundColor','red');
        return
    end    

    fid = fopen('SDR_USB_FW.hex');
    if fid == -1
        set(handles.MessageWindow,'String','Hex file error','ForegroundColor','red');
        return
    end
    i=0;
    while 1
        tline = fgetl(fid);
        if tline == -1
            set(handles.MessageWindow,'String','Hex file read  error','ForegroundColor','red');
            return
        end
        if tline(2:3) == '00'
            break
        end
        i = i+1;
        codedata{i,1} = int64(hex2dec(tline(2:3)));
        codedata{i,2} = uint16(hex2dec(tline(4:7)));
        bincode = uint8([]);
        for j = 10:2:(size(tline,2)-2)
            bincode((j-8)/2) = uint8(hex2dec(tline(j:(j+1))));
        end
        codedata{i,3} = bincode;
    end
    fclose(fid);
    linesdone = usbdownload(codedata);
    if linesdone~=(i-1)
        set(handles.MessageWindow,'String','Firmware download error','ForegroundColor','red');
        return
    end

    instruction = hex2dec('FA00');
    ForwardData = zeros(512,1)+instruction;
    SendOutData = uint16(ForwardData);

    OutLength=miniradarputdata(SendOutData,handles.EndPoint2_Num);
    DataLength  = 512 + 2048;
    [PUPradarBoardInfo,InLength] = miniradargetdata(handles.EndPoint6_Num,DataLength);
    PUPradarBoardInfo = dec2hex(PUPradarBoardInfo(1025:1100),4); 
    if PUPradarBoardInfo(1,:) == 'FA05'
        % Frequency band info
        handles.FrequencyBand = hex2dec(PUPradarBoardInfo(2,3:4));    %New protocol 240=xFA
        % Num of channels info
       handles.Num_Tx = hex2dec(PUPradarBoardInfo(3, 1));
       handles.Num_Rx = hex2dec(PUPradarBoardInfo(3, 2));
       handles.AntennaType = hex2dec(PUPradarBoardInfo(3, 3:4)); 
       handles.Version = hex2dec(PUPradarBoardInfo(4, 2)); 
       Version=hex2dec(PUPradarBoardInfo(4, 1:2));
       modelcode=handles.FrequencyBand*1000000+handles.Num_Tx*100000+handles.Num_Rx*10000+handles.AntennaType*100+handles.Version;
       handles.modelcode=modelcode;
       
       if modelcode==24240100
            handles.model='Model  PUP_DU24P_T2R4';% band=24(24G)Old module name.
       elseif modelcode==240240100
            handles.model='Model  PUP_EN24P_T2R4';% band=240 24GHz new define.
       elseif modelcode==240240200
            handles.model='Model  PUP_EN24C_T2R4 V1';% band=240 24GHz new define. 
       elseif modelcode==240240202
            handles.model='Model  PUP_EN24C_T2R4 V2';% band=240 24GHz new define.
       elseif modelcode==240140201
            handles.model='Model  PUP_EN24C_T1R4';
       else
            handles.model='Needs Refresh';
       end 
    else
       handles.model='';

    end   
     %handles.PUP_model = sprintf('%d%c%d%c', FrequencyBand, 'T', handles.ActiveNum_Tx, 'R', LANR);
     %handles.model = sprintf('%d%c%d%c', handles.FrequencyBand, 'T', handles.Num_Tx, 'R', handles.Num_Rx);
   [Newhandles]=handles;     
   guidata(hObject,handles);


% --- Get complex data from CHx channel for Sawtooth.
function [ComplexDataTx1, ComplexDataTx2, NumSweeps] = GetComplexData( handles )
% Input: 
% NumSweeps: number of sweeps needed
% handles: structure handles to the figure
% 
% Output:           
% ComplexDataTx1: complex samples requested
% ComplexDataTx2: complex samples requested

%NumSweeps=handles.NumSweeps;
LASNV=handles.ActiveSamplingNumberValue; 
LASN=handles.SN_Selections(LASNV);
LANT=handles.ActiveNum_Tx;
LANR=handles.ActiveNum_Rx;
LARS=handles.ActiveReceiverString; 
LATS=handles.ActiveTransmitterString;
NumSweeps=handles.NumSweeps;
LASNperSweep=LASN*LANR*2*LANT; %LASN*LANR*2*LANT=samplingNumber/PerSweep
% Transfer data from MCU 
DataLength = ceil((NumSweeps+40) * LASN *2 * LANR * LANT/ 512)*512 + 4096;
[RawData,InLength] = miniradargetdata(handles.EndPoint6_Num,DataLength);
%save RawData RawData
% Discard 2048 leftover data samples 
RawData = double(RawData(2049:end)); 

       modelcode=handles.modelcode;
% Data check and remove headers
if LANT == 1          % Device has 1 Tx channels
    if  LATS=='Tx1'
          try 
            Tx1Index = find(RawData>=49152);    %find and remove Tx1 header
            %Tx1IndexDifference = diff(Tx1Index);
            RawData(Tx1Index) = RawData(Tx1Index) - 49152;           
            ValidSweepNumber=(Tx1Index(end-1)-Tx1Index(1))/(LASN*2*LANR);
            if NumSweeps>ValidSweepNumber
               NumSweeps=ValidSweepNumber;
               handles.NumSweeps=ValidSweepNumber;
            end
            ValidData = RawData(Tx1Index(1):Tx1Index(end-1)+LASN*2*LANR-1); % *2: I&Q
            DataMatrixTx1 = reshape(ValidData, LASN*2*LANR,[]); 
            DMTX1=size(DataMatrixTx1);
            if LANR==1
                 if (LARS=='Rx1') 
                ComplexDataTx1(1 :LASN,1:NumSweeps) =DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps) + ...
                              DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*1i; 
                          
                 elseif (LARS=='Rx2') 
                ComplexDataTx1(1 :LASN,1:NumSweeps) =DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps) + ...
                              DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*1i;
                          
                 elseif (LARS=='Rx3')                     
                ComplexDataTx1(1 :LASN,1:NumSweeps) =DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps) + ...
                             DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*1i;
                 save rx3 ComplexDataTx1;             
                 elseif (LARS=='Rx4')                         
                ComplexDataTx1(1 :LASN,1:NumSweeps) =DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps) + ...
                              DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*1i;                          
                 end 
                ComplexDataTx2 = zeros(LASN, NumSweeps); 
            elseif LANR==2
                if (LARS=='Rx1.Rx2') 
                ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:4:LASN*4-3, 1:NumSweeps) + ...
                             DataMatrixTx1(2:4:LASN*4-2, 1:NumSweeps)*1i;
                ComplexDataTx1(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx1(3:4:LASN*4-1, 1:NumSweeps) + ...
                             DataMatrixTx1(4:4:LASN*4,1:NumSweeps)*1i;

                elseif (LARS=='Rx3.Rx4' )                          
                ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:4:LASN*4-3, 1:NumSweeps) + ...
                             DataMatrixTx1(2:4:LASN*4-2, 1:NumSweeps)*1i;
                ComplexDataTx1(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx1(3:4:LASN*4-1, 1:NumSweeps) + ...
                             DataMatrixTx1(4:4:LASN*4,1:NumSweeps)*1i; 
                end      
                ComplexDataTx2 = zeros(LASN*2, NumSweeps);            
             elseif LANR==4
                ComplexDataTx1(1 :LASN,1:NumSweeps) = -DataMatrixTx1(1:8:LASN*8-7, 1:NumSweeps)*1i + ...
                             DataMatrixTx1(2:8:LASN*8-6, 1:NumSweeps);
                ComplexDataTx1(LASN+1:LASN*2,1:NumSweeps) = -DataMatrixTx1(3:8:LASN*8-5, 1:NumSweeps)*1i + ...
                             DataMatrixTx1(4:8:LASN*8-4,1:NumSweeps);    
                ComplexDataTx1(LASN*2+1 :LASN*3,1:NumSweeps) = -DataMatrixTx1(5:8:LASN*8-3, 1:NumSweeps)*1i + ...
                             DataMatrixTx1(6:8:LASN*8-2, 1:NumSweeps);
                ComplexDataTx1(LASN*3+1:LASN*4,1:NumSweeps) = -DataMatrixTx1(7:8:LASN*8-1, 1:NumSweeps)*1i + ...
                             DataMatrixTx1(8:8:LASN*8,1:NumSweeps);    
                ComplexDataTx2 = zeros(LASN*4, NumSweeps);                        
            end
        catch
            ComplexDataTx1 = zeros(LASN*4, NumSweeps); 
            ComplexDataTx2 = zeros(LASN*4, NumSweeps); 
            return           
        end
     
     elseif LATS=='Tx2'
        try 
            Tx2Index = find(RawData>=32768);   %find and remove Tx2 header
           % Tx2IndexDifference = diff(Tx2Index);
            RawData(Tx2Index) = RawData(Tx2Index) - 32768;   
            ValidSweepNumber=(Tx2Index(end-1)-Tx2Index(1))/(LASN*2*LANR);
            if NumSweeps>ValidSweepNumber
                NumSweeps=ValidSweepNumber;
                handles.NumSweeps=ValidSweepNumber;
            end      
            ValidData = RawData(Tx2Index(1):Tx2Index(end-1)+LASN*2*LANR-1); % *2: I&Q //*4: for those Tx2 output power smaller
            DataMatrixTx2 = reshape(ValidData, LASN*2*LANR,[]); 
            if LANR==1
                
                 if (LARS=='Rx1')  
                 ComplexDataTx2(1 :LASN,1:NumSweeps) =DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps) + ...
                              DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*1i; 
                       
                 elseif(LARS=='Rx2')
                 ComplexDataTx2(1 :LASN,1:NumSweeps) =DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps) + ...
                              DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*1i; 
                          
                 elseif (LARS=='Rx3')
                  ComplexDataTx2(1 :LASN,1:NumSweeps) =DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps) + ...
                              DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*1i;                          
                          
                 elseif (LARS=='Rx4')
                 ComplexDataTx2(1 :LASN,1:NumSweeps) =DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps) + ...
                              DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*1i;                           
                          
                 end
                ComplexDataTx1 = zeros(LASN, NumSweeps); 
            elseif LANR==2
                if (LARS=='Rx1.Rx2')
                ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:4:LASN*4-3, 1:NumSweeps)+ ...
                             DataMatrixTx2(2:4:LASN*4-2, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx2(3:4:LASN*4-1, 1:NumSweeps) + ...
                             DataMatrixTx2(4:4:LASN*4,1:NumSweeps)*1i;

                elseif (LARS=='Rx3.Rx4' )  
                ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:4:LASN*4-3, 1:NumSweeps) + ...
                             DataMatrixTx2(2:4:LASN*4-2, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx2(3:4:LASN*4-1, 1:NumSweeps) + ...
                             DataMatrixTx2(4:4:LASN*4,1:NumSweeps)*1i; 
                end
                         
                ComplexDataTx1 = zeros(LASN*2, NumSweeps);            
             elseif LANR==4
                ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:8:LASN*8-7, 1:NumSweeps) + ...
                             DataMatrixTx2(2:8:LASN*8-6, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx2(3:8:LASN*8-5, 1:NumSweeps) + ...
                             DataMatrixTx2(4:8:LASN*8-4,1:NumSweeps)*1i;    
                ComplexDataTx2(LASN*2+1 :LASN*3,1:NumSweeps) = DataMatrixTx2(5:8:LASN*8-3, 1:NumSweeps) + ...
                             DataMatrixTx2(6:8:LASN*8-2, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN*3+1:LASN*4,1:NumSweeps) = DataMatrixTx2(7:8:LASN*8-1, 1:NumSweeps) + ...
                             DataMatrixTx2(8:8:LASN*8,1:NumSweeps)*1i;    
                ComplexDataTx1 = zeros(LASN*4, NumSweeps);                        
            end
        catch
            ComplexDataTx1 = zeros(LASN*4, NumSweeps); 
            ComplexDataTx2 = zeros(LASN*4, NumSweeps);  
            return
        end     
    end   
else  % Device has 2 Tx channels
    try
        Tx1Index = find(RawData>=49152);
       % Tx1IndexDiff = diff(Tx1Index); %can be used to check data lose
        Tx2Index = find(RawData<49150 & RawData>=32768);
       % Tx2IndexDiff = diff(Tx2Index); %can be used to check data lose

        % remove headers
        RawData(Tx1Index) = RawData(Tx1Index)-49152; %find and remove Tx1 header
        RawData(Tx2Index) = RawData(Tx2Index)-32768; %find and remove Tx2 header
        ValidSweepNumber=(Tx2Index(end-1)-Tx1Index(1))/(LASN*2*LANR*LANT);
        if NumSweeps>ValidSweepNumber
           NumSweeps=ValidSweepNumber;
        end
        ValidData = RawData(Tx1Index(1):Tx1Index(1)+LASN*2*LANR*LANT*NumSweeps-1); 
        DataMatrix = reshape(ValidData, LASN*2*LANR,[]); 
        DataMatrixTx1 = DataMatrix(:, 1:2:NumSweeps*2);  
        DataMatrixTx2 = DataMatrix(:, 2:2:NumSweeps*2);  
        if LANR==1  % here Rx order needs to be used to convert Rx1 for Q=-Q
             if (LARS=='Rx1') 
            ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*4*1i; 
            ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*4*1i;
             elseif (LARS=='Rx2')
            ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*4*1i; 
            ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*4*1i;             
             elseif (LARS=='Rx3') 
            ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*4*1i; 
            ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*4*1i; 
                              
             elseif (LARS=='Rx4') 
            ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*4*1i; 
            ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*4*1i;                  
                 
             end
        elseif LANR==2
            if (LARS=='Rx1.Rx2')
            ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:4:LASN*4-3, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(2:4:LASN*4-2, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx1(3:4:LASN*4-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(4:4:LASN*4,1:NumSweeps)*4*1i;                   
            ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:4:LASN*4-3, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(2:4:LASN*4-2, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx2(3:4:LASN*4-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(4:4:LASN*4,1:NumSweeps)*4*1i;
            elseif (LARS=='Rx3.Rx4' ) 
            ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:4:LASN*4-3, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(2:4:LASN*4-2, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx1(3:4:LASN*4-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(4:4:LASN*4,1:NumSweeps)*4*1i;                   
            ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:4:LASN*4-3, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(2:4:LASN*4-2, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx2(3:4:LASN*4-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(4:4:LASN*4,1:NumSweeps)*4*1i;                  
            end
        elseif LANR==4                                              
            ComplexDataTx1(1 :LASN,1:NumSweeps) = DataMatrixTx1(1:8:LASN*8-7, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(2:8:LASN*8-6, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx1(3:8:LASN*8-5, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(4:8:LASN*8-4,1:NumSweeps)*4*1i;                    
            ComplexDataTx1(LASN*2+1 :LASN*3,1:NumSweeps) = DataMatrixTx1(5:8:LASN*8-3, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(6:8:LASN*8-2, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN*3+1:LASN*4,1:NumSweeps) = DataMatrixTx1(7:8:LASN*8-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx1(8:8:LASN*8,1:NumSweeps)*4*1i;                   
            ComplexDataTx2(1 :LASN,1:NumSweeps) = DataMatrixTx2(1:8:LASN*8-7, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(2:8:LASN*8-6, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN+1:LASN*2,1:NumSweeps) = DataMatrixTx2(3:8:LASN*8-5, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(4:8:LASN*8-4,1:NumSweeps)*4*1i;    
            ComplexDataTx2(LASN*2+1 :LASN*3,1:NumSweeps) = DataMatrixTx2(5:8:LASN*8-3, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(6:8:LASN*8-2, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN*3+1:LASN*4,1:NumSweeps) = DataMatrixTx2(7:8:LASN*8-1, 1:NumSweeps)*4 + ...
                                                  DataMatrixTx2(8:8:LASN*8,1:NumSweeps)*4*1i;                                                                                                                                                                            
        end
    catch
         ComplexDataTx1 = zeros(LASN*4, NumSweeps); 
         ComplexDataTx2 = zeros(LASN*4, NumSweeps);  
         return
    end  
end
NewComplexDataTx1=ComplexDataTx1;
NewComplexDataTx2=ComplexDataTx2;   


% --- Executes on button press in radiobuttonDTx1.
function radiobuttonDTx1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDTx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.radiobuttonDTx1, 'value', 1);
set(handles.radiobuttonDTx2, 'value', 0);         
handles.ActiveDisplayChannelTx='Tx1';
guidata(hObject, handles);
[handles]=SetActiveParameters(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonDTx1


% --- Executes during object creation, after setting all properties.
function radiobuttonDTx1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonDTx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in radiobuttonDTx2.
function radiobuttonDTx2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDTx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.radiobuttonDTx1, 'value', 0);
set(handles.radiobuttonDTx2, 'value', 1);         
handles.ActiveDisplayChannelTx='Tx2';
guidata(hObject, handles);
[handles]=SetActiveParameters(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of radiobuttonDTx2


% --- Executes during object creation, after setting all properties.
function radiobuttonDTx2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonDTx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonRx4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonRx12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonRx34_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonRx34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonRxAll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonRxAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function radiobuttonDRx3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonDRx3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function radiobuttonDRx4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobuttonDRx4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
