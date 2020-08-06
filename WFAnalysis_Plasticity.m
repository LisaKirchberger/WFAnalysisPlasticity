%% Cleanup workspace
clear all %#ok<CLALL>
close all
clc
warning('off','MATLAB:ui:actxcontrol:FunctionToBeRemoved')


%% Set the parameters
AnalysisParameters.Project = 'Mouse_Plasticity';
AnalysisParameters.Mice = {'Fergon', 'Hodor', 'Irri', 'Jon', 'Lysa', 'Meryn', 'Ned', 'Osha', 'Pyat'};                                                           
Tasks = {'EasyOptoDetection_PassiveMultiLaser', 'EasyOptoDetection', 'EasyOptoDetection_Passive'};
Taskchoice = menu('Choose the Task',Tasks);
AnalysisParameters.Task = Tasks{Taskchoice}; clear Tasks Taskchoice;

AnalysisParameters.OverwriteData = 0;
AnalysisParameters.RedoAllenBrainAlignment = 0;
AnalysisParameters.RedoRegistration = 0;
AnalysisParameters.ExcludeTrialsWithMotion = 1;
AnalysisParameters.MotionThreshold = 15;
AnalysisParameters.PlotFigures = 'off';
AnalysisParameters.BaselineTime = 200;                                      % in ms
AnalysisParameters.StimTime = 500;                                          % in ms
AnalysisParameters.PostStimTime = 500;
AnalysisParameters.ScriptsDir = 'D:\GitHub\WFAnalysisPlasticity';
AnalysisParameters.PlotAreas = {'VIS', 'VISp', 'VISal', 'VISam', 'VISl', 'VISli', 'VISpl', 'VISpm', 'VISpor', 'PTLp', 'CTXpl', 'SS', 'AUD', 'MO', 'RSP'};


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

%% Create Trial Data by loading all data that should be analysed, registering it to reference image (from pRF) and preprocess data (downsample to 400x400 and put in correct timeline)
createTrialData(AnalyseDataDets,AnalysisParameters)

%% Create Eye and Motion Tracking Table from all data that should be analysed
createEyeMotionTable(AnalyseDataDets,AnalysisParameters)

%% Create Condition Data
createCondData(AnalyseDataDets,AnalysisParameters)

%% Create Timecourses for the different conditions
createCondTimecourseTable(AnalyseDataDets, AnalysisParameters)

%% Analyse the Data & make plots
makeCondVideos(AnalyseDataDets, AnalysisParameters)

%% Plot timecourses for each session
plotTimecoursesSession(AnalyseDataDets, AnalysisParameters)

%% Plot some timecourses
if strcmp(AnalysisParameters.Task ,'EasyOptoDetection_PassiveMultiLaser')
    plotTimecourses_EasyOptoDetection_PassiveMultiLaser(AnalysisParameters)
    makeCondVideos_EasyOptoDetection_PassiveMultiLaser(AnalysisParameters)
    makeVideos_arrow_EasyOptoDetection_PassiveMultiLaser(AnalysisParameters)
    plotTimecourses_AVG_MultiLaser(AnalysisParameters)
    for i = 1:size(AnalyseDataDets.SessID,2)
        averageRedChn
    end
    extractTdTomFluor(AnalysisParameters)
end


