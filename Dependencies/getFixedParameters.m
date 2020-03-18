function AnalysisParameters = getFixedParameters(AnalysisParameters)

% Directories
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
AnalysisParameters.CondTimecourseTablePath = [AnalysisParameters.DataDirectory AnalysisParameters.Task '\CondTimecourseTable.mat'];


% other unimportant paramters, should just stay the same
AnalysisParameters.useImType = 'tiff';
AnalysisParameters.ScaleFact = 0.5; 
AnalysisParameters.Pix = 800*AnalysisParameters.ScaleFact;
AnalysisParameters.SmoothFact = 0;    
AnalysisParameters.AREAS = {'V1','Vl','Val','Vrl','Va','Vam','Vpm','RSP','M1','M2'};
AnalysisParameters.Exposure = 50;
AnalysisParameters.Timeline = -AnalysisParameters.BaselineTime:AnalysisParameters.Exposure:AnalysisParameters.StimTime+AnalysisParameters.BaselineTime;


end

