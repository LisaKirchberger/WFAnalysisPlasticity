function createCondTimecourseTable(AnalyseDataDets,AnalysisParameters)

%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')


%% go through the wanted Sessions and put all timecourses in a table, do this for the whole Cortex, and the right and left hemisphere

Hemispheres = {'WholeCortex', 'RightHemisphere', 'LeftHemisphere'};
Filenames = {fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable.mat'), fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable_R.mat'), fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable_L.mat')};
AreaMasksNames = {'Model.AreaMask', 'Model.AreaMaskR', 'Model.AreaMaskL'};

for h = 1:length(Hemispheres)

    % load or create a CondTimecourseTable
    if exist(Filenames{h}, 'file')
        load(Filenames{h})
    else
        CondTimecourseTable = table();
        save(Filenames{h}, 'CondTimecourseTable')
    end

    for s = AnalyseDataDets.SessID
        
        %% Parameters
        
        Mouse = char(SessionLUT.MouseName(s));
        Conditions = CondLUT.CondID(CondLUT.SessID == s);
        
        
        %% load the Allen Brain Model
        
        Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
        load(Allenmodelpath, 'Model')
        eval(['AreaMasks = ' AreaMasksNames{h} ';'])
        
        for c = Conditions'
            
            %% Load the Condition Data
            load(fullfile(AnalysisParameters.CondWFDataPath, sprintf('CondID_%d.mat', c)), 'Cond_dFF_avg')
            Timepoints = size(Cond_dFF_avg,3);
            
            %% go through the areas and extract aveage timecourse for each area
            
            for a = 1:length(Model.AreaMask)
                myMask = repmat(AreaMasks{a},[1,1,Timepoints]);
                numPixels = sum(sum(AreaMasks{a}));
                AreaPixelResponse = Cond_dFF_avg(myMask);
                AreaPixelResponse = reshape(AreaPixelResponse, [numPixels, Timepoints]);
                AreaResponse = nanmean(AreaPixelResponse,1); %#ok<NASGU>
                eval([Model.AreaName{a} '=' 'AreaResponse;'])
            end
            
            %% store the timecourses in the table (CondTimecourseTable)
            
            CondID = c; %#ok<NASGU>
            TableVars = ['CondID, ' sprintf('%s, ', Model.AreaName{1:end-1}) Model.AreaName{end}];
            eval(['tmptable = table(' TableVars ');'])
            CondTimecourseTable = [CondTimecourseTable; tmptable]; %#ok<AGROW>
            clear tmptable
            
            save(Filenames{h}, 'CondTimecourseTable')
            
        end
        
    end
end


end
