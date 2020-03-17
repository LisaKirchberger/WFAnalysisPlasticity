function AnalyzeDataDets = gatherDataInfo_Database(AnalysisParameters)


%% STILL NEEDS DEBUGGING 



%% Get all the wanted Data

% for this script to work need to install Datajoint, clone from Github: https://github.com/datajoint/datajoint-matlab  
% also need to add DJ +roelfsemalab to your path!

% This Script looks through all JSON files of the given AnalysisParameters.Mice and selects the
% paths of the Sessions you want to analyse
% if AnalysisParameters.Overwrite = 1; it will just take all paths of that AnalysisParameters.Task it can find
% if AnalysisParameters.Overwrite = 0; it will check if the Session has already been preprocessed and just append data that is still missing

% AnalysisParameters.Mice - name of the mouse you want to find all sessions of interest from
% AnalysisParameters.RawDataDirectory - path to directory with raw data and logfiles
% AnalysisParameters.Task - name of the task you want to analyse
% AnalysisParameters.Overwrite - do you want to rerun the preprocessing for all data



%% if want to overwrite all Data, create an empty SessionLUT and Delete the currently present preprocessed Data

if AnalysisParameters.OverwriteData == 1 || ~exist(AnalysisParameters.SessionLUTPath, 'file')
    % create empty Session lookup table
    LogfileName = [];
    SessID = [];
    DataPath = [];
    LogfilePath = [];
    SessionLUT = table(LogfileName, SessID, DataPath, LogfilePath);
    save(AnalysisParameters.SessionLUTPath, 'SessionLUT')
    % create empty tall array for Data
    delete(AnalysisParameters.preprocWFDataPath)
    preProcWFData = tall;  %#ok<*NASGU>
    preProcWFData = [];
    save(AnalysisParameters.preprocWFDataPath, 'preProcWFData')
end


%% load the Session lookup table

load(AnalysisParameters.SessionLUTPath)


%% Look through all JSON files in the AnalysisParameters.RawDataDirectory

% get all the paths of the wanted Tasks by using JSON files
setenv('DJ_HOST', 'nhi-fyd.nin.knaw.nl')
setenv('DJ_USER', 'dbuser')
setenv('DJ_PASS', 'SoUrhy8nEmMQk51Q')
Con = dj.conn();
JSONfiles = [];
counter = 1;

for m = 1:size(AnalysisParameters.Mice,2)
    query = roelfsemalab.Sessions & ['Stimulus="' AnalysisParameters.Task '"'] & ...
                    ['Project="' AnalysisParameters.Project '"'] & ...
                    ['Subject="' AnalysisParameters.Mice{m} '"'];
    JSONpaths = query.fetch('subject', 'url', 'excond', 'stimulus', 'server');
    
    if ~isempty(JSONpaths)
        for i = 1:size(JSONpaths,1)
            JSONfiles{counter} = fullfile(strrep(JSONpaths(i).url, './', ['\\' JSONpaths(i).server '\']));
            DirComponents = strsplit(JSONfiles{counter}, '\');
            AnalyzeDataDets.DataPath{counter} = ['\\' fullfile(DirComponents{1:end-1})];
            
%             
%             AnalyzeDataDets.LogfilePath{count} = fullfile(logPath.folder, logPath.name);
%             AnalyzeDataDets.Mouse{count} = jsonData.subject;
%             AnalyzeDataDets.SessID(count) = count;
%             
%             % Fill in SessionLUT
%             LogfileName = cellstr(jsonData.logfile);
%             SessID = count;
%             Date = cellstr(jsonData.date);
%             DataPath = cellstr(logPath.folder);
%             LogfilePath = cellstr(fullfile(logPath.folder, logPath.name));
%             tmptable = table(LogfileName, SessID, Date, DataPath, LogfilePath);
%             SessionLUT = [SessionLUT; tmptable]; %#ok<AGROW>
%             count = count + 1;
%             counter = counter + 1;
        end
    end
end


save(AnalysisParameters.SessionLUTPath, 'SessionLUT')

end

