function createCondData(AnalyseDataDets,AnalysisParameters)

for s = AnalyseDataDets.SessID
    
    fprintf('Creating condition data for SessionID %s  \n', num2str(s))
    
    %% load in newest version of the lookup tables and the already processed data and the logfile
    
    load(AnalysisParameters.TrialLUTPath)
    load(AnalysisParameters.SessionLUTPath)
    load(AnalysisParameters.CondLUTPath)
    load(fullfile(AnalysisParameters.DataTablePath,'EyeMotionTable.mat'), 'EyeMotionTable')
    
    %% Conditions
    
    CondID = size(CondLUT,1)+1;
    usedConds = unique(TrialLUT.TrialCond(TrialLUT.SessID == s));
    gotRefImage = 0;
    
    for c = usedConds'
        
        %% get all trials of this condition, take & save average
        
        wantedTrials = TrialLUT.TrialID(TrialLUT.SessID == s & TrialLUT.TrialCond == c);
        
        % CondData = 400 x 400 x Time x Trials
        CondData = nan(AnalysisParameters.Pix,AnalysisParameters.Pix,length(AnalysisParameters.Timeline),length(wantedTrials), 'single');
        Motion = [];
        
        % load in Data and put in CondData
        for t = 1:length(wantedTrials)
            filename = fullfile(AnalysisParameters.TrialWFDataPath, sprintf('TrialID_%d.mat', wantedTrials(t)));
            load(filename, 'TrialData')
            CondData(:,:,:,t) = TrialData;
            Motion(t) = EyeMotionTable.Motion(EyeMotionTable.TrialIDs == wantedTrials(t)); %#ok<AGROW>
            clear TrialData
        end
        
        % dFF with trial specific baseline
        TrialBase = nanmean(CondData(:,:,AnalysisParameters.Timeline>=-200 & AnalysisParameters.Timeline<0,:),3);
        dFF = (CondData - repmat(TrialBase,[1,1,length(AnalysisParameters.Timeline),1]))./repmat(TrialBase,[1,1,length(AnalysisParameters.Timeline),1]);
        
        % remove bad trials
        if AnalysisParameters.Trial_zscore
            % take average over time
            dFF_Trial = squeeze(nanmean(dFF,3));
            % extract the brain pixels
            Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' AnalyseDataDets.Mouse{s} '_brainareamodel.mat'];
            load(Allenmodelpath, 'Model')
            Area = 'CTXpl';
            myMask = repmat(Model.AreaMask{strcmp(Model.AreaName, Area)},[1,1,length(wantedTrials)]);
            numPixels = sum(sum(Model.AreaMask{strcmp(Model.AreaName, Area)}));
            AreaPixelResponse = dFF_Trial(myMask);
            AreaPixelResponse = nanmean(reshape(AreaPixelResponse, [numPixels, length(wantedTrials)]),1);
            % z-score the data and remove trials with a z-score >1.5 and <-1.5
            Z = normalize(AreaPixelResponse);
            includedTrials = ~(abs(Z)>1.5);
        else
            includedTrials = true(1,length(wantedTrials));
        end
        
        % remove trials with too much movement
        if AnalysisParameters.ExcludeTrialsWithMotion
            includedTrials(Motion > AnalysisParameters.MotionThreshold) = 0;
        end
        
        
        % take the average
        Cond_dFF_avg = squeeze(nanmean(dFF(:,:,:,includedTrials),4)); 
        
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
        if Cond >= 100 && Cond < 200
            CondWord = cellstr([char(CondWord) ' correct']);% these were correct trials
        elseif Cond >= 200
            CondWord = cellstr([char(CondWord) ' erroneous']);% these were erroneous trials
        end
        TrialIDs = mat2cell(wantedTrials(includedTrials), length(wantedTrials(includedTrials)));
        exclTrialIDs = mat2cell(wantedTrials(~includedTrials), length(wantedTrials(~includedTrials)));
        SessID = s;
        MouseName = SessionLUT.MouseName(s);
        MouseSessID = SessionLUT.MouseSessID(s);
        LogfileName = SessionLUT.LogfileName(s);
        Date = SessionLUT.Date(s);
        DataPath = SessionLUT.DataPath(s);
        LogfilePath = SessionLUT.LogfilePath(s);
        tmptable = table(CondWord, Cond, CondID, TrialIDs, exclTrialIDs, SessID, MouseName, MouseSessID, LogfileName, Date, DataPath, LogfilePath);
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



