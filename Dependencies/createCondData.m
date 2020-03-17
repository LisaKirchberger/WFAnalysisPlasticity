function createCondData(AnalyseDataDets,AnalysisParameters)

for s = AnalyseDataDets.SessID
    
    
    %% load in newest version of the lookup tables and the already processed data and the logfile
    
    load(AnalysisParameters.TrialLUTPath)
    load(AnalysisParameters.SessionLUTPath)
    load(AnalysisParameters.CondLUTPath)
    load(AnalyseDataDets.LogfilePath{s})
    
    Mouse = char(SessionLUT.MouseName(s));
    
    
    %% Conditions
    
    CondID = size(CondLUT,1)+1;
    usedConds = unique(Log_table.TrialCond);
    gotRefImage = 0;
    
    for c = usedConds'
        
        %% get all trials of this condition, take & save average
        
        wantedTrials = TrialLUT.TrialID(TrialLUT.SessID == s & TrialLUT.TrialCond == c);
        
        % CondData = 400 x 400 x Time x Trials
        CondData = nan(AnalysisParameters.Pix,AnalysisParameters.Pix,length(AnalysisParameters.Timeline),length(wantedTrials));
        
        % load in Data and put in CondData
        for t = 1:length(wantedTrials)
            filename = fullfile(AnalysisParameters.TrialWFDataPath, sprintf('TrialID_%d.mat', wantedTrials(t)));
            load(filename, 'TrialData')
            CondData(:,:,:,t) = TrialData;
            clear TrialData
        end
        
        % dFF with trial specific baseline
        TrialBase = nanmean(CondData(:,:,AnalysisParameters.Timeline>=-200 & AnalysisParameters.Timeline<0,:),3);
        dFF = (CondData - repmat(TrialBase,[1,1,length(AnalysisParameters.Timeline),1]))./repmat(TrialBase,[1,1,length(AnalysisParameters.Timeline),1]);
        
        % take the average
        Cond_dFF_avg = nanmean(dFF,4);
        
        clear TrialBase dFF
        
        
        %% Reference Image of Brain
        
        counter1 = 1;
        counter2 = 1;
        while gotRefImage == 0
            RefImage = squeeze(CondData(:,:,counter1,counter2));
            if sum(isnan(RefImage(:))) > 20000
                counter1 = counter1 + 1;
                if counter1 > length(AnalysisParameters.Timeline)
                    counter1 = 1;
                    counter2 = counter2 + 1;
                end
            else
                % save it
                save(fullfile(AnalysisParameters.RefImgPath, sprintf('SessID_%d.mat', s)), 'RefImage');
                gotRefImage = 1;
            end
        end
        clear CondData TrialBase dFF
        
        
        %% fill the CondLUT
        
        CondWord = TrialLUT.Trialword(wantedTrials(1));
        Cond = c;
        TrialIDs = mat2cell(wantedTrials, length(wantedTrials));
        SessID = s;
        MouseName = cellstr(Mouse);
        MouseSessID = SessionLUT.MouseSessID(s);
        LogfileName = SessionLUT.LogfileName(s);
        Date = SessionLUT.Date(s);
        DataPath = SessionLUT.DataPath(s);
        LogfilePath = SessionLUT.LogfilePath(s);
        tmptable = table(CondWord, Cond, CondID, TrialIDs, SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath);
        CondLUT = [CondLUT; tmptable]; %#ok<AGROW>
        clear tmptable
        
        
        %% save the data of this Trial in the Tall Array
        
        fileName = fullfile(AnalysisParameters.CondWFDataPath, sprintf('CondID_%d.mat', CondID));
        save(fileName, 'Cond_dFF_avg')
        clear Cond_dFF_avg
        
        save(AnalysisParameters.CondLUTPath, 'CondLUT')
        CondID = CondID + 1;
        
        
    end %Trials
    
    
end %Sessions

cd(AnalysisParameters.ScriptsDir)


end %Function


