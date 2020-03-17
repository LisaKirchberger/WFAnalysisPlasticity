function AnalyseDataDets = gatherDataInfo(AnalysisParameters)

%% Get all the wanted Data

% This Script looks through all JSON files of the given AnalysisParameters.Mice and selects the
% paths of the Sessions you want to analyse
% if AnalysisParameters.Overwrite = 1; it will just take all paths of that AnalysisParameters.Task it can find
% if AnalysisParameters.Overwrite = 0; it will check if the Session has already been preprocessed and just append data that is still missing


%% if want to overwrite all Data, create an empty SessionLUT and Delete the currently present preprocessed Data

if AnalysisParameters.OverwriteData == 1 || ~exist(AnalysisParameters.SessionLUTPath, 'file')
    % create empty Session lookup table
    SessID = [];MouseName = [];MouseSessID = [];LogfileName = [];Date = [];DataPath = [];LogfilePath = [];
    SessionLUT = table(SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath);
    if ~exist([AnalysisParameters.DataDirectory AnalysisParameters.Task], 'dir')
        mkdir(AnalysisParameters.SessionLUTPath)
    end
    save(AnalysisParameters.SessionLUTPath, 'SessionLUT')
    % Folder for the Trial Data
    if exist(AnalysisParameters.TrialWFDataPath, 'dir')
        rmdir(AnalysisParameters.TrialWFDataPath, 's')
    end
    mkdir(AnalysisParameters.TrialWFDataPath)
    % Folder for the Cond Data
    if exist(AnalysisParameters.CondWFDataPath, 'dir')
        rmdir(AnalysisParameters.CondWFDataPath, 's')
    end
    mkdir(AnalysisParameters.CondWFDataPath)
    % create an empty master Trial Lookup table
    delete(AnalysisParameters.TrialLUTPath)
    TrialLUT = table();
    save(AnalysisParameters.TrialLUTPath, 'TrialLUT')
    % create an empty master Condition Lookup table
    delete(AnalysisParameters.CondLUTPath)
    CondLUT = table();
    save(AnalysisParameters.CondLUTPath, 'CondLUT')
end


%% load the Session lookup table

load(AnalysisParameters.SessionLUTPath)

cd(AnalysisParameters.RawDataDirectory)
SessIDcounter = size(SessionLUT.SessID,1)+1;
AnalyseCounter = 1;

for m = 1:length(AnalysisParameters.Mice)
    MouseCounter = sum(strcmp(SessionLUT.MouseName, AnalysisParameters.Mice{m}))+1;
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
                    if ~strcmpi(SessionLUT.LogfileName, jsonData.logfile)
                        
                        % Read in the Logfile and save
                        logPath = dir([Sessions(s).name(1:end-1) '*.mat']);
                        AnalyseDataDets.DataPath{AnalyseCounter} = SessDir;
                        AnalyseDataDets.LogfilePath{AnalyseCounter} = fullfile(logPath.folder, logPath.name);
                        AnalyseDataDets.Mouse{AnalyseCounter} = jsonData.subject;
                        AnalyseDataDets.SessID(AnalyseCounter) = SessIDcounter;
                        
                        % Fill in SessionLUT SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath
                        SessID = SessIDcounter;
                        MouseName = cellstr(AnalysisParameters.Mice{m});
                        MouseSessID = MouseCounter;
                        LogfileName = jsonData.logfile;
                        if strcmp(LogfileName(end-3:end), '.mat')
                            LogfileName = LogfileName(1:end-4);
                        end
                        LogfileName = cellstr(LogfileName);
                        Date = cellstr(jsonData.date);
                        DataPath = cellstr(logPath.folder);
                        LogfilePath = cellstr(fullfile(logPath.folder, logPath.name));
                        tmptable = table(SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath);
                        SessionLUT = [SessionLUT; tmptable]; %#ok<AGROW>
                        SessIDcounter = SessIDcounter + 1;
                        MouseCounter = MouseCounter +1;
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

end

