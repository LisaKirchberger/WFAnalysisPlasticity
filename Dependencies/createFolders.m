function createFolders(AnalysisParameters)

% if AnalysisParameters.Overwrite = 1; it will first remove all existing folders to then remake them
% if AnalysisParameters.Overwrite = 0; it will just make missing folders

if AnalysisParameters.OverwriteData == 1
    % Folder for the Trial Data
    if exist(AnalysisParameters.TrialWFDataPath, 'dir')
        rmdir(AnalysisParameters.TrialWFDataPath, 's')
    end
    % Folder for the Cond Data
    if exist(AnalysisParameters.CondWFDataPath, 'dir')
        rmdir(AnalysisParameters.CondWFDataPath, 's')
    end
    % Folder for the reference images
    if exist(AnalysisParameters.RefImgPath, 'dir')
        rmdir(AnalysisParameters.RefImgPath, 's')
    end
    % Folder for the Videos
    if exist(AnalysisParameters.VideoPath, 'dir')
        rmdir(AnalysisParameters.VideoPath, 's')
    end
end

if ~exist([AnalysisParameters.DataDirectory AnalysisParameters.Task], 'dir')
    mkdir([AnalysisParameters.DataDirectory AnalysisParameters.Task])
end

if ~exist(AnalysisParameters.TrialWFDataPath, 'dir')
    mkdir(AnalysisParameters.TrialWFDataPath)
end

if ~exist(AnalysisParameters.CondWFDataPath, 'dir')
    mkdir(AnalysisParameters.CondWFDataPath)
end

if ~exist(AnalysisParameters.RefImgPath, 'dir')
    mkdir(AnalysisParameters.RefImgPath)
end

if ~exist(AnalysisParameters.VideoPath, 'dir')
    mkdir(AnalysisParameters.VideoPath)
end

end

