function plotTimecourses(AnalyseDataDets,AnalysisParameters)

%% load in the Trial & Condition % Session LUT

%load(AnalysisParameters.TrialLUTPath, 'TrialLUT')

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
load(AnalysisParameters.CondTimecourseTablePath, 'CondTimecourseTable')

Mice = unique(SessionLUT.MouseName);
    
for m = 1:length(Mice)
    
    %% Parameters
    
    SessIDs = SessionLUT.SessID(strcmp(SessionLUT.MouseName, Mice{m}));
    Mouse = char(SessionLUT.MouseName(SessIDs(1))); 
    for s = SessIDs'
        CondIDs{s} = CondLUT.CondID(CondLUT.SessID == s);
    end
    
    
    %% load the Allen Brain Model
    
    Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
    load(Allenmodelpath, 'Model')

    
    %% plot it for V1 
    % !!!!!!!!!!!! this is just a hack for now !!!!!!!!!!!!!!!!
    SessionTitles = {'pre-training', '1st exposure', 'intermediate', 'expert'};
    Area = 'VISp';
    figure
    subplot(2,3,[1 4])
    imagesc(Model.AreaMask{strcmp(Model.AreaName, Area)});axis square; box off; AdvancedColormap('w b'); axis off; hold on;freezeColors
    plot(Model.AllX, Model.AllY, 'k.', 'MarkerSize', 0.1)
    title(Area)
    Positions = [2 3 5 6];
    for s = 1:length(SessIDs)
        AxesHandle(s) = subplot(2,3,Positions(s)); %#ok<AGROW>
        plot(AnalysisParameters.Timeline./1000, zeros(length(AnalysisParameters.Timeline),1), 'k--');hold on
        Colors = jet(length(CondIDs{s}));
        for c = 1:length(CondIDs{s})
            myRow = find(CondTimecourseTable.CondID == CondIDs{s}(c)); %#ok<NASGU>
            eval(['timecourse = CondTimecourseTable.' Area '(myRow,:);'])
            plot(AnalysisParameters.Timeline./1000, timecourse, 'Color', Colors(c,:))
        end
        box off
        xlabel('Time (s)')
        ylabel('dFF')
        title(SessionTitles{s})
    end
    allYLim = get(AxesHandle, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AxesHandle, 'YLim', [min(allYLim), max(allYLim)]);
    set(AxesHandle, 'XLim', [-0.2 0.55])
    set(AxesHandle, 'TickDir', 'out')
    set(AxesHandle, 'Box', 'off')
    %set(AxesHandle, 'YTick', 'off')

    
end



end
