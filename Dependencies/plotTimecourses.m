function plotTimecourses(AnalyseDataDets,AnalysisParameters)

%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
load(fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable.mat'), 'CondTimecourseTable')

Mice = unique(SessionLUT.MouseName);

for m = 1:length(Mice)
    
    %% Parameters
    
    SessIDs = SessionLUT.SessID(strcmp(SessionLUT.MouseName, Mice{m}));
    Mouse = char(SessionLUT.MouseName(SessIDs(1)));
    if length(SessIDs) > 4
        % pick 4 Sessions to compare
        disp('too many Sessions to plot all at once, pick 4 or change code')
        keyboard
    end
    
    for s = SessIDs'
        CondIDs{s} = CondLUT.CondID(CondLUT.SessID == s);
    end
    
    
    %% load the Allen Brain Model
    
    Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
    load(Allenmodelpath, 'Model')
    
    
    %% plot it for one area and make plots and images
    
    SessionTitles = {'pre-training', '1st exposure', 'intermediate', 'expert'};
    Area = 'VISp';
    
    figure('visible', AnalysisParameters.PlotFigures)
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
        title({SessionTitles{s}; ' '})
    end
    allYLim = get(AxesHandle, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AxesHandle, 'YLim', [min(allYLim), max(allYLim)]);
    set(AxesHandle, 'XLim', [-0.2 0.55])
    set(AxesHandle, 'TickDir', 'out')
    set(AxesHandle, 'Box', 'off')
    
    
    %% one with legend to get the legend for presentations etc
    
    legendtext = {' ', '0.0 mW', '0.1 mW', '0.5 mW', '1.0 mW', '5.0 mW', '10.0 mW'};
    figure('visible', AnalysisParameters.PlotFigures)
    s=1;
    plot(AnalysisParameters.Timeline./1000, zeros(length(AnalysisParameters.Timeline),1), 'k--');hold on
    Colors = jet(length(CondIDs{s}));
    for c = 1:length(CondIDs{s})
        myRow = find(CondTimecourseTable.CondID == CondIDs{s}(c)); %#ok<NASGU>
        eval(['timecourse = CondTimecourseTable.' Area '(myRow,:);'])
        plot(AnalysisParameters.Timeline./1000, timecourse, 'Color', Colors(c,:), 'LineWidth', 1)
    end
    box off
    xlabel('Time (s)')
    ylabel('dFF')
    legend(legendtext)
    title({SessionTitles{s}; ' '})
    FigName = fullfile(AnalysisParameters.TimecoursePlotPath, [Mouse '_XYZ_Legend']);
    saveas(gcf, FigName, 'tiff')
    close(gcf)
    
        
    %% plot it for all areas and store as images
    
    AreaNames = CondTimecourseTable.Properties.VariableNames;
    AreaNames(strcmp(AreaNames, 'CondID')) = [];
    Hemispheres = {'WholeCortex', 'RightHemisphere', 'LeftHemisphere'};
    AreaMasks_all = {Model.AreaMask, Model.AreaMaskR, Model.AreaMaskL};
    Filenames = {fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable.mat'), fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable_R.mat'), fullfile(AnalysisParameters.CondWFDataPath,'CondTimecourseTable_L.mat')};
    
    for h = 1:length(Hemispheres)
        
        AreaMasks = AreaMasks_all{h};
        load(Filenames{h}, 'CondTimecourseTable')
        
        for a = 1:length(AreaNames)
            Area = AreaNames{a};
            
            figure('visible', 'off')
            subplot(2,3,[1 4])
            imagesc(AreaMasks{strcmp(Model.AreaName, Area)});axis square; box off; AdvancedColormap('w b'); axis off; hold on;freezeColors
            plot(Model.AllX, Model.AllY, 'k.', 'MarkerSize', 0.1)
            title(Area)
            Positions = [2 3 5 6];
            for s = 1:length(SessIDs)
                AxesHandle(s) = subplot(2,3,Positions(s));
                plot(AnalysisParameters.Timeline./1000, zeros(length(AnalysisParameters.Timeline),1), 'k--');hold on
                Colors = jet(length(CondIDs{s}));
                for c = 1:length(CondIDs{s})
                    myRow = find(CondTimecourseTable.CondID == CondIDs{s}(c)); %#ok<NASGU>
                    eval(['timecourse = CondTimecourseTable.' Area '(myRow,:);'])
                    plot(AnalysisParameters.Timeline./1000, timecourse, 'Color', Colors(c,:), 'LineWidth', 1)
                end
                box off
                xlabel('Time (s)')
                ylabel('dFF')
                title({SessionTitles{s}; ' '})
            end
            allYLim = get(AxesHandle, {'YLim'});
            allYLim = cat(2, allYLim{:});
            set(AxesHandle, 'YLim', [min(allYLim), max(allYLim)]);
            set(AxesHandle, 'XLim', [-0.2 0.55])
            set(AxesHandle, 'TickDir', 'out')
            set(AxesHandle, 'Box', 'off')
            
            % save & close figure
            if ~exist(fullfile(AnalysisParameters.TimecoursePlotPath,Hemispheres{h}), 'dir')
                mkdir(fullfile(AnalysisParameters.TimecoursePlotPath,Hemispheres{h}))
            end
            FigName = fullfile(AnalysisParameters.TimecoursePlotPath,Hemispheres{h}, [Mouse '_' Area]);
            saveas(gcf, FigName, 'tiff')
            close(gcf)
        end
    end
    
end



end
