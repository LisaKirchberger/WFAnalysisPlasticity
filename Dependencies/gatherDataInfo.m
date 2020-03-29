function AnalyseDataDets = gatherDataInfo(AnalysisParameters)

%% Get all the wanted Data

% This Script looks through all JSON files of the given AnalysisParameters.Mice and selects the
% paths of the Sessions you want to analyse
% if AnalysisParameters.Overwrite = 1; it will just take all paths of that AnalysisParameters.Task it can find
% if AnalysisParameters.Overwrite = 0; it will check if the Session has already been preprocessed and just append data that is still missing

AnalyseDataDets.DataPath = [];
AnalyseDataDets.LogfilePath = [];
AnalyseDataDets.RawEyeMotionPath = [];
AnalyseDataDets.EyeMotionPath = [];
AnalyseDataDets.Mouse = [];
AnalyseDataDets.SessID = [];
AnalyseDataDets.MouseSessID = [];
                        

%% if want to overwrite all Data, create an empty SessionLUT and Delete the currently present preprocessed Data

if AnalysisParameters.OverwriteData == 1 || ~exist(AnalysisParameters.SessionLUTPath, 'file')
    % create empty Session Lookup table
    SessID = []; MouseName = []; MouseSessID = []; LogfileName = []; Date = []; DataPath = []; LogfilePath = []; EyeMotionPresent = []; EyeMotionPath = [];
    SessionLUT = table(SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath, EyeMotionPresent, EyeMotionPath);
    save(AnalysisParameters.SessionLUTPath, 'SessionLUT')
    % create an empty Trial Lookup table
    TrialLUT = table(); %#ok<*NASGU>
    save(AnalysisParameters.TrialLUTPath, 'TrialLUT')
    % create an empty Condition Lookup table
    CondLUT = table();
    save(AnalysisParameters.CondLUTPath, 'CondLUT')
    % create an empty condition timecourse table
    CondTimecourseTable = table();
    save(fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable.mat'), 'CondTimecourseTable')
    save(fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable_R.mat'), 'CondTimecourseTable')
    save(fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable_L.mat'), 'CondTimecourseTable')
    % create an empty Eye and Motion Table
    EyeMotionTable = table();
    save(AnalysisParameters.EyeMotionTablePath, 'EyeMotionTable');
end


%% load the Session lookup table

load(AnalysisParameters.SessionLUTPath)

cd(AnalysisParameters.RawDataDirectory)
SessID = size(SessionLUT.SessID,1)+1;
AnalyseCounter = 1;

for m = 1:length(AnalysisParameters.Mice)
    MouseSessID = sum(strcmp(SessionLUT.MouseName, AnalysisParameters.Mice{m}))+1;
    MouseDir = fullfile(AnalysisParameters.RawDataDirectory, AnalysisParameters.Mice{m});
    cd(MouseDir)
    
    Days = dir(fullfile(MouseDir,[AnalysisParameters.Mice{m} '*']));
    for d = 1:length(Days)
        DateDir = fullfile(MouseDir, Days(d).name);
        cd(DateDir)
        
        Sessions = dir(fullfile(DateDir,[AnalysisParameters.Mice{m} '*'])); dirflags = [Sessions.isdir];Sessions(~dirflags) = [];
        for s = 1:length(Sessions)
            SessDir = fullfile(DateDir,Sessions(s).name);
            cd(SessDir)
            
            % Read the JSON file to see which AnalysisParameters.Task it was
            jsonPath = dir([Sessions(s).name(1:end-1) '*.json']);
            if ~isempty(jsonPath)
                jsonData = readJSONfile(jsonPath.name);
                if strcmpi(jsonData.stimulus, AnalysisParameters.Task)
                    
                    % Check if this Session is already present in the Session LUT, if so just jump to next one
                    if ~strcmpi(SessionLUT.LogfileName, jsonData.logfile(1:end-4))
                        
                        % Read in the Logfile and save
                        logPath = dir([Sessions(s).name(1:end-1) '*.mat']);
                        AnalyseDataDets.DataPath{AnalyseCounter} = SessDir;
                        AnalyseDataDets.LogfilePath{AnalyseCounter} = fullfile(logPath.folder, logPath.name);
                                TmpDir = strsplit(logPath.folder, 'RawData\');EyeMotionDir = [AnalysisParameters.RawEyeMotionDataDirectory TmpDir{end} '\'];EyeMotionPath = dir(fullfile(EyeMotionDir, '*.dat'));
                        if ~isempty(EyeMotionPath)
                            AnalyseDataDets.RawEyeMotionPath{AnalyseCounter} = fullfile(EyeMotionPath.folder, EyeMotionPath.name);
                        else
                            AnalyseDataDets.RawEyeMotionPath{AnalyseCounter} = [];
                        end
                        AnalyseDataDets.EyeMotionPath{AnalyseCounter} = fullfile(logPath.folder, 'EyeMotionData.mat');
                        AnalyseDataDets.Mouse{AnalyseCounter} = jsonData.subject;
                        AnalyseDataDets.SessID(AnalyseCounter) = SessID;
                        AnalyseDataDets.MouseSessID(AnalyseCounter) = MouseSessID;
                        
                        % Fill in SessionLUT SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath
                        MouseName = cellstr(AnalysisParameters.Mice{m});
                        LogfileName = jsonData.logfile;
                        if strcmp(LogfileName(end-3:end), '.mat')
                            LogfileName = LogfileName(1:end-4);
                        end
                        LogfileName = cellstr(LogfileName);
                        Date = cellstr(jsonData.date);
                        DataPath = cellstr(logPath.folder);
                        LogfilePath = cellstr(fullfile(logPath.folder, logPath.name));
                        if ~isempty(AnalyseDataDets.RawEyeMotionPath{AnalyseCounter})
                            EyeMotionPresent = 1;
                            EyeMotionPath = AnalyseDataDets.EyeMotionPath(AnalyseCounter);
                        else
                            EyeMotionPresent = 0;
                            EyeMotionPath{1} = [];
                        end
                        tmptable = table(SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath, EyeMotionPresent, EyeMotionPath);
                        SessionLUT = [SessionLUT; tmptable]; %#ok<AGROW>
                        SessID = SessID + 1;
                        MouseSessID = MouseSessID + 1;
                        AnalyseCounter = AnalyseCounter +1;
                        
                        disp(['Added ' Days(d).name ', session ' Sessions(s).name])
                    end
                end
            end
            
        end                                                                 % end of looping over s
        
    end                                                                     % end of looping over Dates
end

%% Save the SessionLUT

save(AnalysisParameters.SessionLUTPath, 'SessionLUT')
cd(AnalysisParameters.ScriptsDir)


end

