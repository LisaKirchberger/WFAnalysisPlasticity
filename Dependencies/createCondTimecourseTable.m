function createCondTimecourseTable(AnalyseDataDets,AnalysisParameters)

%% load in the Trial & Condition % Session LUT

%load(AnalysisParameters.TrialLUTPath, 'TrialLUT')

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
if exist(AnalysisParameters.CondTimecourseTablePath, 'file')
    load(AnalysisParameters.CondTimecourseTablePath)
else
    CondTimecourseTable = table();
    save(AnalysisParameters.CondTimecourseTablePath, 'CondTimecourseTable')
end

%% go through the wanted Sessions and put all timecourses in a table

for s = AnalyseDataDets.SessID
    
    %% Parameters
    Mouse = char(SessionLUT.MouseName(s));
    LogName = char(SessionLUT.LogfileName(s));
    Conditions = CondLUT.CondID(CondLUT.SessID == s);
    
    
    %% load the Allen Brain Model
    
    Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
    load(Allenmodelpath, 'Model')

    for c = Conditions'
        
        %% Load the Condition Data
        load(fullfile(AnalysisParameters.CondWFDataPath, sprintf('CondID_%d.mat', c)), 'Cond_dFF_avg')
        Timepoints = size(Cond_dFF_avg,3);
        
        %% go through the areas and extract aveage timecourse for each area 
        
        for a = 1:length(Model.AreaMask)
            myMask = repmat(Model.AreaMask{a},[1,1,Timepoints]);
            numPixels = sum(sum(Model.AreaMask{a}));
            AreaPixelResponse = Cond_dFF_avg(myMask);
            AreaPixelResponse = reshape(AreaPixelResponse, [numPixels, Timepoints]);
            AreaResponse = nanmean(AreaPixelResponse,1); %#ok<NASGU>
            eval([Model.AreaName{a} '=' 'AreaResponse;'])
        end
        
        %% store the timecourses in the table (CondTimecourseTable)
        
        CondID = c;
        TableVars = ['CondID, ' sprintf('%s, ', Model.AreaName{1:end-1}) Model.AreaName{end}];
        eval(['tmptable = table(' TableVars ');'])
        CondTimecourseTable = [CondTimecourseTable; tmptable]; %#ok<AGROW>
        clear tmptable
        
        save(AnalysisParameters.CondTimecourseTablePath, 'CondTimecourseTable') 
        
        
        
        
    end
    
end



end
