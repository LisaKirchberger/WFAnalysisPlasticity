%% Cleanup workspace
clear all %#ok<CLALL>
close all
clc

%% Set the parameters
AnalysisParameters.Project = 'Mouse_Plasticity';
AnalysisParameters.Mice = {'Fergon'};                                       % {'Arja','Bran','Fergon', 'Hodor'};                                                           
AnalysisParameters.Task ='EasyOptoDetection_PassiveMultiLaser';

AnalysisParameters.OverwriteData = 1;
AnalysisParameters.RedoAllenBrainAlignment = 0;
AnalysisParameters.RedoRegistration = 0;
AnalysisParameters.PlotFigures = 'off';
AnalysisParameters.BaselineTime = 200;                                      % in ms
AnalysisParameters.StimTime = 500;                                          % in ms
AnalysisParameters.ScriptsDir = pwd;

%% Add needed functions
cd(AnalysisParameters.ScriptsDir)
addpath(genpath(AnalysisParameters.ScriptsDir))

%% read in more fixed parameters
AnalysisParameters = getFixedParameters(AnalysisParameters);

%% Create needed folders
createFolders(AnalysisParameters)

%% Select which data to analyse by reading in the logfiles & storing in info 
AnalyseDataDets = gatherDataInfo(AnalysisParameters); 
cd(AnalysisParameters.ScriptsDir)

%% Load Allen Brain Map & fit it to mouse cortex using pRF map
alignAllenBrainMap(AnalyseDataDets,AnalysisParameters) 

%% Create Trial Data by loading all data that should be analyzed, registering it to reference image (from pRF) and preprocess data (downsample to 400x400 and put in correct timeline)
createTrialData(AnalyseDataDets,AnalysisParameters)

%% Create Condition Data
createCondData(AnalyseDataDets,AnalysisParameters)

%% Analyse the Data & make plots
AnalysisParameters.PlotFigures = 'on';
eval(['makeVideos_', AnalysisParameters.Task '(AnalyseDataDets,AnalysisParameters)'])
