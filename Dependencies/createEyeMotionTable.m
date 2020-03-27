function createEyeMotionTable(AnalyseDataDets,AnalysisParameters)

for s = 1:size(AnalyseDataDets.SessID,2)
    
    fprintf('Creating eyetracking and motion data for SessionID %s \n', num2str(AnalyseDataDets.SessID(s)))
    Mouse = AnalyseDataDets.Mouse{s};
    
    %% load in the logfile & the current version of the EyeMotionTable
    
    load(AnalysisParameters.EyeMotionTablePath, 'EyeMotionTable')
    load(AnalyseDataDets.LogfilePath{s}, 'Log_table')
    nTrials = max(Log_table.Trial);
    
    
    %% make variables for table later
    
    TrialIDs = (size(EyeMotionTable,1)+1:size(EyeMotionTable,1)+nTrials)';
    EyeX_tc = nan(nTrials, length(AnalysisParameters.Timeline));
    EyeY_tc = nan(nTrials, length(AnalysisParameters.Timeline));
    EyeH_tc = nan(nTrials, length(AnalysisParameters.Timeline));
    EyeW_tc = nan(nTrials, length(AnalysisParameters.Timeline));
    Motion_tc = nan(nTrials, length(AnalysisParameters.Timeline));
    
    %% if there is no Eye and rawMotion Data for this session, fill the table with NaNs and continue to next session
    
    if isempty(AnalyseDataDets.RawEyeMotionPath{s}) && ~exist(AnalyseDataDets.EyeMotionPath{s}, 'file')
        EyeX = nanmean(EyeX_tc,2);
        EyeY = nanmean(EyeY_tc,2);
        EyeH = nanmean(EyeH_tc,2);
        EyeW = nanmean(EyeW_tc,2);
        Motion = nanmean(Motion_tc,2);
        EyeMotionTableSess = table(TrialIDs, EyeX, EyeY, EyeH,  EyeW, Motion, EyeX_tc, EyeY_tc, EyeH_tc, EyeW_tc, Motion_tc);
        save(AnalyseDataDets.EyeMotionPath{s}, 'EyeMotionTableSess')
        EyeMotionTable = [EyeMotionTable; EyeMotionTableSess];
        save(AnalysisParameters.EyeMotionTablePath, 'EyeMotionTable')
        continue
    end
    
    
    %% Extract Eye and rawMotion Data if hasn't been exctracted yet
    
    if ~exist(AnalyseDataDets.EyeMotionPath{s}, 'file')
        
        %% read in Eye and rawMotion Data (can take several tries!)
        
        attempts = 1;
        extractedData = false;
        while attempts < 50 && ~extractedData
            try
                [rawEye, rawTrigger, rawMotion] = readpupil(AnalyseDataDets.RawEyeMotionPath{s});
                extractedData = true;
            catch
                attempts = attempts + 1;
            end
        end
        
        rawEye=rawEye';
        rawTrigger=rawTrigger';
        rawMotion=rawMotion';
        
        %% sometimes the dasbit gets registered twice, remove all dasbit 1s that are not separated from another dasbit 1 by a dasbit 0 (which is there when there is no stimulus in the ITI) or that are not separated more than the ITI
        
        DAS1idx = find(rawTrigger(:,2) == 1);
        ITI = Log_table.ITI(1)*1000;
        wantedTriggers = false(length(DAS1idx),1);
        for t = 1:length(DAS1idx)
            if t==1 ||  rawTrigger(DAS1idx(t),1)-rawTrigger(DAS1idx(t-1),1)>ITI
                wantedTriggers(t) = 1;
            end
        end
        if sum(wantedTriggers) ~= nTrials
            keyboard
        end
        wantedDAS1idx = DAS1idx(wantedTriggers);
        TrialStartTime = rawTrigger(wantedDAS1idx,1);
        
        
        %% extract motion and eye data around the trial start time in the frequency of AnalysisParameters.Timeline
        
        for trial = 1:nTrials
            for time = 1:length(AnalysisParameters.Timeline)
                wantedPupilidx = rawEye(:,1)-TrialStartTime(trial)>= AnalysisParameters.Timeline(time) & rawEye(:,1)-TrialStartTime(trial)<= AnalysisParameters.Timeline(time)+AnalysisParameters.Exposure;
                wantedMotionidx = rawMotion(:,1)-TrialStartTime(trial)>= AnalysisParameters.Timeline(time) & rawMotion(:,1)-TrialStartTime(trial)<= AnalysisParameters.Timeline(time)+AnalysisParameters.Exposure;
                if sum(wantedPupilidx)>0
                    EyeX_tc(trial, time) = mean(rawEye(wantedPupilidx,2));
                    EyeY_tc(trial, time) = mean(rawEye(wantedPupilidx,3));
                    EyeH_tc(trial, time) = mean(rawEye(wantedPupilidx,4));
                    EyeW_tc(trial, time) = mean(rawEye(wantedPupilidx,5));
                end
                if sum(wantedMotionidx)>0
                    Motion_tc(trial, time) = mean(rawMotion(wantedMotionidx,2));
                end
            end
        end
        
        
        %% take the average over time and store in table
        
        EyeX = nanmean(EyeX_tc,2);
        EyeY = nanmean(EyeY_tc,2);
        EyeH = nanmean(EyeH_tc,2);
        EyeW = nanmean(EyeW_tc,2);
        Motion = nanmean(Motion_tc,2);
        
        EyeMotionTableSess = table(TrialIDs, EyeX, EyeY, EyeH,  EyeW, Motion, EyeX_tc, EyeY_tc, EyeH_tc, EyeW_tc, Motion_tc);
        save(AnalyseDataDets.EyeMotionPath{s}, 'EyeMotionTableSess')
        
    end
    
    load(AnalyseDataDets.EyeMotionPath{s}, 'EyeMotionTableSess')
    EyeMotionTable = [EyeMotionTable; EyeMotionTableSess];
    save(AnalysisParameters.EyeMotionTablePath, 'EyeMotionTable')
        
end %Sessions

cd(AnalysisParameters.ScriptsDir)

end %Function



