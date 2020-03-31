function AnalysisParameters = getFixedParameters(AnalysisParameters)

% Directories
% AnalysisParameters.RawDataDirectory = '\\VC2NIN\Mouse_Plasticity\RawData\';
% AnalysisParameters.DataDirectory = '\\VC2NIN\Mouse_Plasticity\ppData\';
% AnalysisParameters.pRFMappingDir = '\\VC2NIN\Mouse_Plasticity\pRFData\';
% AnalysisParameters.AllenBrainModelDir = '\\VC2NIN\Mouse_Plasticity\ppData\AllenBrainAlignment';
AnalysisParameters.RawDataDirectory = '\\vs02\VandC\BU\Lisa\RawData\';
AnalysisParameters.RawEyeMotionDataDirectory = [AnalysisParameters.RawDataDirectory 'EyeMotionData\'];
AnalysisParameters.DataDirectory = '\\vs02\VandC\BU\Lisa\ppData\';
AnalysisParameters.pRFMappingDir = '\\vs02\VandC\BU\Lisa\pRFData\';
AnalysisParameters.AllenBrainModelDir = '\\vs02\VandC\BU\Lisa\ppData\AllenBrainAlignment';
AnalysisParameters.LocalFolder = 'E:\Lisa\';
AnalysisParameters.TaskDataPath = [AnalysisParameters.DataDirectory AnalysisParameters.Task];
AnalysisParameters.TrialWFDataPath = [AnalysisParameters.TaskDataPath '\TrialWFData'];
AnalysisParameters.CondWFDataPath = [AnalysisParameters.TaskDataPath '\CondWFData'];
AnalysisParameters.RefImgPath = [AnalysisParameters.TaskDataPath '\RefImg'];
AnalysisParameters.VideoPath = [AnalysisParameters.TaskDataPath '\Videos'];
AnalysisParameters.DataTablePath = [AnalysisParameters.TaskDataPath '\DataTables'];
AnalysisParameters.TimecoursePlotPath = [AnalysisParameters.TaskDataPath '\TimecoursePlots'];
AnalysisParameters.SessionLUTPath = [AnalysisParameters.TaskDataPath '\SessionLUT.mat'];
AnalysisParameters.TrialLUTPath = [AnalysisParameters.TaskDataPath '\TrialLUT.mat'];
AnalysisParameters.CondLUTPath = [AnalysisParameters.TaskDataPath '\CondLUT.mat'];

% other unimportant paramters, should just stay the same
AnalysisParameters.ScaleFact = 0.5; 
AnalysisParameters.Pix = 800*AnalysisParameters.ScaleFact;
AnalysisParameters.SmoothFact = 0;    
AnalysisParameters.Exposure = 50;
AnalysisParameters.Timeline = -AnalysisParameters.BaselineTime:AnalysisParameters.Exposure:AnalysisParameters.StimTime+AnalysisParameters.BaselineTime;

if strcmp(AnalysisParameters.Task, 'EasyOptoDetection_PassiveMultiLaser')
    AnalysisParameters.ExcludedSessions = {'Irri_20200121_B1', 'Jon_20200122_B1', 'Lysa_20200124_B1'};
else
    AnalysisParameters.ExcludedSessions = {};
end

end

