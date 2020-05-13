function plotTimecoursesSession(AnalyseDataDets,AnalysisParameters)

%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
load(fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable.mat'), 'CondTimecourseTable')

for s = AnalyseDataDets.SessID
    
    Mouse = char(SessionLUT.MouseName(s));
    SessFolderName = fullfile(AnalysisParameters.TimecoursePlotPath, 'Sessions', ['SessID_' num2str(s) '_' SessionLUT.LogfileName{SessionLUT.SessID==s}]);
    CondIDs = CondLUT.CondID(CondLUT.SessID == s);
    
    if ~exist(SessFolderName, 'dir')
        mkdir(SessFolderName)
    end
    
    
    %% load the Allen Brain Model
    
    Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
    load(Allenmodelpath, 'Model')
    

    %% plot it for all areas and store as images
    
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
            subplot(1,2,1)
            imagesc(AreaMasks{strcmp(Model.AreaName, Area)});axis square; box off; AdvancedColormap('w b'); axis off; hold on;freezeColors
            plot(Model.AllX, Model.AllY, 'k.', 'MarkerSize', 0.1)
            title(Area)
            AxesHandle = subplot(1,2,2);
            plot(AnalysisParameters.Timeline./1000, zeros(length(AnalysisParameters.Timeline),1), 'k--');hold on
            Colors = jet(length(CondIDs));
            for c = 1:length(CondIDs)
                myRow = find(CondTimecourseTable.CondID == CondIDs(c)); %#ok<NASGU>
                eval(['timecourse = CondTimecourseTable.' Area '(myRow,:);'])
                plot(AnalysisParameters.Timeline./1000, timecourse, 'Color', Colors(c,:), 'LineWidth', 1)
            end
            box off
            xlabel('Time (s)')
            ylabel('dFF')
            TitleText = strsplit(SessionLUT.LogfileName{SessionLUT.SessID==s}, '_'); TitleText = sprintf('%s ', TitleText{:});
            title({TitleText; ' '})
            set(AxesHandle, 'XLim', [-0.2 0.55])
            set(AxesHandle, 'TickDir', 'out')
            set(AxesHandle, 'Box', 'off')
            
            % save & close figure
            if ~exist(fullfile(SessFolderName,Hemispheres{h}), 'dir')
                mkdir(fullfile(SessFolderName,Hemispheres{h}))
            end
            FigName = fullfile(SessFolderName,Hemispheres{h}, [SessionLUT.LogfileName{SessionLUT.SessID==s} '_' Area]);
            saveas(gcf, FigName, 'tiff')
            close(gcf)
        end
    end
    
end



end
