function plotTimecourses_EasyOptoDetection_PassiveMultiLaser(AnalysisParameters)

%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
load(fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable.mat'), 'CondTimecourseTable')

Mice = unique(SessionLUT.MouseName);

%% select SessionIDs

for m = 1:length(Mice)
    Mouse = Mice{m};
    switch Mouse
        case 'Fergon'
            wantedSessions = {'Fergon_20191022_B1', 'Fergon_20191119_B2', 'Fergon_20191203_B2', 'Fergon_20191217_B3'};
            LearningMouse(m) = true;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
        case 'Hodor'
            wantedSessions = {'Hodor_20191022_B1', 'Hodor_20191127_B3', 'Hodor_20191211_B2', 'Hodor_20191218_B2'};
            LearningMouse(m) = true;
            for s = 1:length(wantedSessions)
                 SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
        case 'Irri'
            wantedSessions = {'Irri_20200127_B1', 'Irri_20200128_B2', 'Irri_20200211_B2', 'Irri_20200225_B2'};
            LearningMouse(m) = false;
            for s = 1:length(wantedSessions)
                 SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
        case 'Jon'
            wantedSessions = {'Jon_20200127_B1', 'Jon_20200129_B2', 'Jon_20200212_B2', 'Jon_20200219_B2'};
            LearningMouse(m) = false;
            for s = 1:length(wantedSessions)
                 SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
        case 'Lysa'
            % not enough data yet
            continue
            wantedSessions = {'Lysa_20200124_B4'};
            LearningMouse(m) = true;
            for s = 1:length(wantedSessions)
                 SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
    end
end


%% make plots for each mouse 

for m = 1:length(SessIDs)
    
    %% Parameters
    
    Mouse = Mice{m};
    
    for s = 1:length(SessIDs{m})
        CondIDs{s} = CondLUT.CondID(CondLUT.SessID ==  SessIDs{m}(s));
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
    for s = 1:length(SessIDs{m})
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
    
    %legendtext = {' ', '0.0 mW', '0.1 mW', '0.5 mW', '1.0 mW', '5.0 mW', '10.0 mW'};
    legendtext = {' ', '10.0 mW', '5.0 mW', '1.0 mW', '0.5 mW', '0.1 mW', '0.0 mW'};
    figure('visible', AnalysisParameters.PlotFigures)
    s=1;
    plot(AnalysisParameters.Timeline./1000, zeros(length(AnalysisParameters.Timeline),1), 'k--');hold on
    Colors = jet(length(CondIDs{s}));
    for c = length(CondIDs{s}):-1:1
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
    
                %AreaNames = CondTimecourseTable.Properties.VariableNames;
                %AreaNames(strcmp(AreaNames, 'CondID')) = [];
    AreaNames = AnalysisParameters.PlotAreas;
    Hemispheres = {'WholeCortex', 'RightHemisphere', 'LeftHemisphere'};
    AreaMasks_all = {Model.AreaMask, Model.AreaMaskR, Model.AreaMaskL};
    Filenames = {fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable.mat'), fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable_R.mat'), fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable_L.mat')};
    
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
            for s = 1:length(SessIDs{m})
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


%% now plot average for learning and control mice

ExpGroups = {'Learning', 'Control'};

for group = 1:2
%    keyboard
end

end
