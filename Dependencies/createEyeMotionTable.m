function createEyeMotionTable(AnalyseDataDets,AnalysisParameters)

if ~exist(fullfile(AnalysisParameters.DataTablePath,'EyeMotionTable.mat'), 'file')
    EyeMotionTable = table();
    save(fullfile(AnalysisParameters.DataTablePath,'EyeMotionTable.mat'), 'EyeMotionTable');
end

for s = 1:size(AnalyseDataDets.SessID,2)
    
    fprintf('Creating eyetracking and motion data for SessionID %s \n', num2str(AnalyseDataDets.SessID(s)))
    Mouse = AnalyseDataDets.Mouse{s};
    
    %% load in the logfile & the current version of the EyeMotionTable
    
    load(fullfile(AnalysisParameters.DataTablePath,'EyeMotionTable.mat'), 'EyeMotionTable')
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
        save(fullfile(AnalysisParameters.DataTablePath,'EyeMotionTable.mat'), 'EyeMotionTable')
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
                fprintf('Attempt %d at reading in Eye and Motion data \n', attempts)
                pause(0.5)
            end
        end
        
        if ~extractedData
            try
                [FileName, FilePath] = uigetfile(AnalyseDataDets.RawEyeMotionPath{s});
                FullFileName = [FilePath FileName];
                [rawEye, rawTrigger, rawMotion] = readpupil(FullFileName);
                extractedData = true;
            catch
                keyboard
            end
        end
        
        rawEye=rawEye';
        rawTrigger=rawTrigger';
        rawMotion=rawMotion';
        
        %% sometimes the dasbit gets registered twice, remove all dasbit 1s that are not separated from another dasbit 1 by a dasbit 0 (which is there when there is no stimulus in the ITI) or that are not separated more than the ITI
        
        % The triggers '0' are the ones when a stimbit was received 
        chan0 = rawTrigger(rawTrigger(:,2)==0,1);
        TimeDiff = diff([0;chan0]);
        wantedTriggers = TimeDiff>Log_table.ITI(1)*1000;
        TrialStartTime = chan0(wantedTriggers);
        
        if length(TrialStartTime) > nTrials                       %too many triggers beginning, so remove those (always check though!, note: checked many sessions now and it was always the first trials)
            figure;subplot(1,2,1);plot(diff(TrialStartTime));title(sprintf('Too many triggers %d out of %d', length(TrialStartTime), nTrials));ylabel('ITI')
            TrialStartTime = TrialStartTime(length(TrialStartTime)-nTrials+1:end);
            subplot(1,2,2);plot(diff(TrialStartTime));title(sprintf('After removing first triggers %d out of %d', length(TrialStartTime), nTrials));ylabel('ITI')
            keyboard %check if this makes sense
        elseif length(TrialStartTime) < nTrials                   % too few triggers
            keyboard
        end
        
        
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
        
        clear rawTrigger rawEye rawMotion TrialIDs EyeX EyeY EyeH EyeW Motion EyeX_tc EyeY_tc EyeH_tc EyeW_tc Motion_tc
        
    end
    
    load(AnalyseDataDets.EyeMotionPath{s}, 'EyeMotionTableSess')
    EyeMotionTable = [EyeMotionTable; EyeMotionTableSess];
    save(fullfile(AnalysisParameters.DataTablePath,'EyeMotionTable.mat'), 'EyeMotionTable')
        
end %Sessions

cd(AnalysisParameters.ScriptsDir)

end %Function



