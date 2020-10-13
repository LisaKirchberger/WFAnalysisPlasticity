function plotTimecourses_AVG_MultiLaser(AnalysisParameters)

warning('off','MATLAB:ui:actxcontrol:FunctionToBeRemoved')


%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
load(fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable.mat'), 'CondTimecourseTable')

ExpGroupNames = {'Learning', 'Control', 'Anesthetized'};
ExpGroup{1} = {'Fergon','Hodor'};                       % Learning mice
ExpGroup{2} = {'Irri','Jon'};                           % Control mice
ExpGroup{3} = {'Meryn','Ned','Osha','Pyat'};            % Anesthetized mice

% for Anesthetized Group, shift relative to Tamoxifen injection
ImagingWeekShift = [5 5 5 5];
SessionLUT.ImagingWeek = SessionLUT.MouseSessID;
for m = 1:length(ExpGroup{3})
    SessionLUT.ImagingWeek(strcmp(SessionLUT.MouseName,ExpGroup{3}{m}))=SessionLUT.MouseSessID(strcmp(SessionLUT.MouseName,ExpGroup{3}{m}))+ImagingWeekShift(m)-1;
    
    % after week 11 imaged only every other week
    every2IDX = find(strcmp(SessionLUT.MouseName,ExpGroup{3}{m}) & SessionLUT.ImagingWeek > 11);
    for i = every2IDX
       SessionLUT.ImagingWeek(i) = 11 + (SessionLUT.ImagingWeek(i)-11)*2;
    end
    
    % after week 17 imaged 3 weeks later 
    every3IDX = find(strcmp(SessionLUT.MouseName,ExpGroup{3}{m}) & SessionLUT.ImagingWeek > 17);
    for i = every3IDX
       SessionLUT.ImagingWeek(i) = SessionLUT.ImagingWeek(i)+1;
    end
    
    % after week 20 imaged 5 weeks later 
    every5IDX = find(strcmp(SessionLUT.MouseName,ExpGroup{3}{m}) & SessionLUT.ImagingWeek > 20);
    for i = every5IDX
       SessionLUT.ImagingWeek(i) = SessionLUT.ImagingWeek(i)+3;
    end
    
end


%% average across mice for anesthetized (for now)

AUCtable=table();

for g = 1:length(ExpGroup)
    
    Mice = ExpGroup{g};
    Mouse = Mice{1};
    
    %% load the Allen Brain Model for example mouse
    
    Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
    load(Allenmodelpath, 'Model')
    
    
    %% go through areas and extract time course % then AUC
    
    AreaNames = AnalysisParameters.PlotAreas;
    Hemispheres = {'WholeCortex', 'RightHemisphere', 'LeftHemisphere'};
    AreaMasks_all = {Model.AreaMask, Model.AreaMaskR, Model.AreaMaskL};
    Filenames = {fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable.mat'), fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable_R.mat'), fullfile(AnalysisParameters.DataTablePath,'CondTimecourseTable_L.mat')};
    wantedTP = AnalysisParameters.Timeline./1000>0 &  AnalysisParameters.Timeline./1000<=0.5;
    
    
    for h = 1:length(Hemispheres)
        
        AreaMasks = AreaMasks_all{h};
        load(Filenames{h}, 'CondTimecourseTable')
        
        for a = 1:length(AreaNames)
            Area = AreaNames{a};
            Conds = unique(CondLUT.Cond);
            Colors = jet(length(Conds));
            
            figure('visible', AnalysisParameters.PlotFigures,'Position',[917   422   780   420])
            suptitle(ExpGroupNames{g})
            subplot(1,2,1)
            imagesc(AreaMasks{strcmp(Model.AreaName, Area)});axis square; box off; AdvancedColormap('w b'), axis off, hold on%,freezeColors
            plot(Model.AllX, Model.AllY, 'k.', 'MarkerSize', 0.1),title(Area)
            
            subplot(1,2,2)
            for c = Conds' % these are the opto conditions, so 0mW, 0.1mW, 0.5mW, 1mW, 5mW, 10mW
                
                % Go through Imaging Weeks for which Data is present and calculate average activity across mice for this condition
                MatchMice=cellfun(@(x) ismember(x, Mice), SessionLUT.MouseName, 'UniformOutput', 1);
                ImagingSessions = unique(SessionLUT.ImagingWeek(MatchMice));
                AUCData = NaN(length(ImagingSessions),length(Mice));
                for i = 1:length(ImagingSessions)
                    SessIDs = SessionLUT.SessID(SessionLUT.ImagingWeek == ImagingSessions(i) & MatchMice);
                    CondIDs = CondLUT.CondID(ismember(CondLUT.SessID, SessIDs) & CondLUT.Cond == c);
                    % for each CondID (each is a different mouse) calculate the AUC in the wanted time frame
                    for m = 1:length(CondIDs)
                        myRow = find(CondTimecourseTable.CondID == CondIDs(m)); %#ok<NASGU>
                        eval(['timecourse = CondTimecourseTable.' Area '(myRow,:);'])
                        AUCData(i,m)=trapz( AnalysisParameters.Timeline(wantedTP) , timecourse(wantedTP) );
                    end
                end
                AUC = nanmean(AUCData,2)';
                AUCsem = (nanstd(AUCData,0,2)./sqrt(size(AUCData,2)))';
                tmptable=table(repmat(g,length(ImagingSessions),1),repmat(ExpGroupNames(g),length(ImagingSessions),1),...
                    repmat(h,length(ImagingSessions),1),repmat(Hemispheres(h),length(ImagingSessions),1),...
                    repmat(a,length(ImagingSessions),1),repmat(cellstr(Area),length(ImagingSessions),1),...
                    repmat(c,length(ImagingSessions),1),ImagingSessions,AUC',AUCsem',...
                    'VariableNames',{'Group', 'GroupName', 'Hemisphere', 'HemisphereName', 'Area','AreaName','Conditions','ImagingSess','AUC','SEM'});
                AUCtable = [AUCtable;tmptable];
                errorbar(ImagingSessions, AUC,AUCsem,'*-', 'Color', Colors(c,:), 'LineWidth', 1),hold on
            end
            axis square, box off, axis tight,xlim([min(ImagingSessions)-0.5 max(ImagingSessions)+0.5]),set(gca,'TickDir','out'),set(gca,'XTick',ImagingSessions)%,set(gca,'xticklabel',{[]})
            xlabel('weeks since Tamoxifen injection'),ylabel('dFF'),title({'AUC'; '0-0.5s'})
            
            % save & close figure
            if ~exist(fullfile(AnalysisParameters.TimecoursePlotPath,Hemispheres{h}), 'dir')
                mkdir(fullfile(AnalysisParameters.TimecoursePlotPath,Hemispheres{h}))
            end
            FigName = fullfile(AnalysisParameters.TimecoursePlotPath,Hemispheres{h}, [Area '_acrossMice_' ExpGroupNames{g}]);
            saveas(gcf, FigName, 'tiff')
            close(gcf), clear AxesHandle
        end
    end
end

SavePath = [AnalysisParameters.DataTablePath '\AUCtable'];
save(SavePath, 'AUCtable')


%% make an overview plot 

XLabels={'Sessions','Sessions','Weeks since Tamoxifen injection'};

for h = 1:length(Hemispheres)
    for a = 1:length(AreaNames)
        Area = AreaNames{a};
        figure('visible', AnalysisParameters.PlotFigures,'Position',[426 526 1271 316])
        subplot(1,4,1)
        imagesc(AreaMasks{strcmp(Model.AreaName, Area)});axis square; box off; AdvancedColormap('w b'), axis off, hold on%,freezeColors
        plot(Model.AllX, Model.AllY, 'k.', 'MarkerSize', 0.1),title(Area)
        for g = 1:length(ExpGroup)
            AxesHandle(g)=subplot(1,4,g+1);
            for c = Conds'
                w=find(AUCtable.Group==g & AUCtable.Hemisphere==h & AUCtable.Area==a & AUCtable.Conditions==c);
                ImagingSessions=AUCtable.ImagingSess(w);
                AUC = AUCtable.AUC(w);
                AUCsem = AUCtable.SEM(w);
                errorbar(ImagingSessions, AUC,AUCsem,'*-', 'Color', Colors(c,:), 'LineWidth', 1),hold on
            end
            axis square, box off, axis tight,xlim([min(ImagingSessions)-0.5 max(ImagingSessions)+0.5]),set(gca,'TickDir','out'),set(gca,'XTick',ImagingSessions)%,set(gca,'xticklabel',{[]})
            xlabel(XLabels{g}),ylabel('dFF'),title({ExpGroupNames{g},'AUC 0-0.5s'})
        end
        allYLim = get(AxesHandle, {'YLim'});
        allYLim = cat(2, allYLim{:});
        set(AxesHandle, 'YLim', [min(allYLim), max(allYLim)]);
        FigName = fullfile(AnalysisParameters.TimecoursePlotPath,Hemispheres{h}, [Area '_acrossMice_comparison']);
        saveas(gcf, FigName, 'tiff')
        close(gcf), clear AxesHandle
    end
end


end
