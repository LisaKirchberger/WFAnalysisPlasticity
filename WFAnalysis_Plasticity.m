%% Step 1

%% Cleanup workspace
clear all %#ok<CLALL>
close all
clc


%% Set the parameters

% Project details
AnalysisParameters.Project = 'Mouse_Plasticity';
AnalysisParameters.Mice = {'Fergon'};%{'Arja','Bran','Fergon', 'Hodor'};                                                           
AnalysisParameters.Task ='EasyOptoDetection_PassiveMultiLaser';

% Important analysis details, check these!
AnalysisParameters.OverwriteData = 1;
AnalysisParameters.RedoAllenBrainAlignment = 0;
AnalysisParameters.RedoRegistration = 0;
AnalysisParameters.PlotFigures = 'off';
AnalysisParameters.BaselineTime = 200; %in ms
AnalysisParameters.Exposure = 50;
AnalysisParameters.StimTime = 500;
AnalysisParameters.Timeline = -AnalysisParameters.BaselineTime:AnalysisParameters.Exposure:AnalysisParameters.StimTime+AnalysisParameters.BaselineTime;

% Directories
AnalysisParameters.ScriptsDir = 'D:\GitHub\Mouse\ImagingAnalysis\Plasticity';%pwd
% AnalysisParameters.RawDataDirectory = '\\VC2NIN\Mouse_Plasticity\RawData\';
% AnalysisParameters.DataDirectory = '\\VC2NIN\Mouse_Plasticity\ppData\';
% AnalysisParameters.pRFMappingDir = '\\VC2NIN\Mouse_Plasticity\pRFData\';
% AnalysisParameters.AllenBrainModelDir = '\\VC2NIN\Mouse_Plasticity\ppData\AllenBrainAlignment';
AnalysisParameters.RawDataDirectory = '\\vs02\VandC\BU\Lisa\RawData\';
AnalysisParameters.DataDirectory = '\\vs02\VandC\BU\Lisa\ppData\';
AnalysisParameters.pRFMappingDir = '\\vs02\VandC\BU\Lisa\pRFData\';
AnalysisParameters.AllenBrainModelDir = '\\vs02\VandC\BU\Lisa\ppData\AllenBrainAlignment';
AnalysisParameters.LocalFolder = 'E:\Lisa\';
AnalysisParameters.TrialWFDataPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\TrialWFData'];
AnalysisParameters.CondWFDataPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\CondWFData'];
AnalysisParameters.RefImgPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\RefImg'];
AnalysisParameters.VideoPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\Videos'];
AnalysisParameters.SessionLUTPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\SessionLUT.mat'];
AnalysisParameters.TrialLUTPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\TrialLUT.mat'];
AnalysisParameters.CondLUTPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\CondLUT.mat'];

% other unimportant paramters, should just stay the same
AnalysisParameters.useImType = 'tiff';
AnalysisParameters.ScaleFact = 0.5; 
AnalysisParameters.Pix = 800*AnalysisParameters.ScaleFact;
AnalysisParameters.SmoothFact = 0;    %Smoothing with neighbours (Gaussian); fill in standard deviation, Enny uses 2
AnalysisParameters.AREAS = {'V1','Vl','Val','Vrl','Va','Vam','Vpm','RSP','M1','M2'};

%% Add needed functions
cd(AnalysisParameters.ScriptsDir)
addpath(genpath(AnalysisParameters.ScriptsDir))
  

%% Select which data to analyse by reading in the logfiles & storing in info 
AnalyseDataDets = gatherDataInfo(AnalysisParameters); 
cd(AnalysisParameters.ScriptsDir)


%% Load Alan Brain Map onto mouse brains
alignAllenBrainMap(AnalyseDataDets,AnalysisParameters) 


%% Load all data that should be analyzed, register to reference image and preprocess data (downsample to 400x400 and put in correct timeline)
createTrialData(AnalyseDataDets,AnalysisParameters)


%% Make Condition Data
createCondData(AnalyseDataDets,AnalysisParameters)


%% Analyse the Data & make plots
eval(['makeVideos_', AnalysisParameters.Task '(AnalyseDataDets,AnalysisParameters)'])
