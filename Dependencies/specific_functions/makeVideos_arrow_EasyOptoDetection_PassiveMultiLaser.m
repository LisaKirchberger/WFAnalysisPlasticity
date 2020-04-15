function makeVideos_arrow_EasyOptoDetection_PassiveMultiLaser(AnalysisParameters)

%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.TrialLUTPath, 'TrialLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
load(AnalysisParameters.SessionLUTPath, 'SessionLUT')

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
            ArrowPos{m}= [];
        case 'Hodor'
            wantedSessions = {'Hodor_20191022_B1', 'Hodor_20191127_B3', 'Hodor_20191211_B2', 'Hodor_20191218_B2'};
            LearningMouse(m) = true;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos{m}= [];
        case 'Irri'
            wantedSessions = {'Irri_20200127_B1', 'Irri_20200128_B2', 'Irri_20200211_B2', 'Irri_20200225_B2'};
            LearningMouse(m) = false;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos{m}= [];
        case 'Jon'
            wantedSessions = {'Jon_20200127_B1', 'Jon_20200129_B2', 'Jon_20200212_B2', 'Jon_20200219_B2'};
            LearningMouse(m) = false;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos{m}= [];
        case 'Lysa'
            % not enough data yet
            continue
            wantedSessions = {'Lysa_20200124_B4'};
            LearningMouse(m) = true;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos{m}= [];
    end
end


%% pick arrow Position

for m = 1:length(Mice)
    Mouse = Mice{m};
    if isempty(ArrowPos{m})
        % get a crisp image by averaging across many raw images during the baseline period
        tmpImages = nan(AnalysisParameters.Pix,AnalysisParameters.Pix,100);
        imageCounter = 1;
        SessFolders = dir(SessionLUT.DataPath{SessionLUT.SessID == SessIDs{m}(1)});
        SessFolders(~[SessFolders.isdir]) = [];
        load(fullfile(SessionLUT.DataPath{SessionLUT.SessID == SessIDs{m}(1)}, 'AligningResults.mat'), 'TM');
        while imageCounter < 100
            for f = 1:length(SessFolders)
                wantedFiles =  dir(fullfile(SessFolders(f).folder, SessFolders(f).name, '*stim0*'));
                for i = 1:length(wantedFiles)
                    tmpImage = imread(fullfile(wantedFiles(i).folder, wantedFiles(i).name));
                    tmpImage = imwarp(tmpImage,TM,'OutputView',imref2d([AnalysisParameters.Pix/AnalysisParameters.ScaleFact AnalysisParameters.Pix/AnalysisParameters.ScaleFact]));
                    tmpImages(:,:,imageCounter) = imresize(tmpImage,AnalysisParameters.ScaleFact);
                    imageCounter = imageCounter + 1;
                end
            end
            continue
        end
        avgImage = uint16(nanmean(tmpImages,3));
        tmplocation = ['D:\Dropbox\19.18.03 FF Plasticity\AVGImages\', Mouse '.tif'];
        imwrite(avgImage, tmplocation)
        clear tmpImage tmpImages imageCounter SessFolders wantedFiles TM avgImage
    end
end


%% Make overview video for the 4 stages contrasting learning and control mice

PlotMice = {'Irri', 'Jon'};
MouseNumbers = [3 4];
PlotConds = [2,4,6];
PlotCondNames = {'0.1mW', '1mW', '10mW', '0.1mW', '1mW', '10mW'};
SessConds = {'preTraining', '1stExposure', 'intermediate', 'expert'};

% Load the AllenBrainModel for both mice
Mouse = PlotMice{1};
Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
load(Allenmodelpath, 'Model')
BrainBoundary = [Model.Boundary{strcmp(Model.AreaName, 'CTXpl')}; Model.Boundary{strcmp(Model.AreaName, 'SCs')}];
BrainMask = false(AnalysisParameters.Pix,AnalysisParameters.Pix);
for b = 1:length(BrainBoundary)
    BrainMask(poly2mask(BrainBoundary{b}(:,1),BrainBoundary{b}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = true;
end
alphaVal = 0.5;
BrainMaskShade = BrainMask-BrainMask.*alphaVal;
load(fullfile(AnalysisParameters.RefImgPath, sprintf('SessID_%d.mat', SessIDs{MouseNumbers(1)}(1))), 'RefImage');
Model1=Model;BrainMask1=BrainMask;BrainMaskShade1=BrainMaskShade;RefImage1=RefImage;
clear Model BrainMask BrainMaskShade RefImage

Mouse = PlotMice{2};
Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
load(Allenmodelpath, 'Model')
BrainBoundary = [Model.Boundary{strcmp(Model.AreaName, 'CTXpl')}; Model.Boundary{strcmp(Model.AreaName, 'SCs')}];
BrainMask = false(AnalysisParameters.Pix,AnalysisParameters.Pix);
for b = 1:length(BrainBoundary)
    BrainMask(poly2mask(BrainBoundary{b}(:,1),BrainBoundary{b}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = true;
end
alphaVal = 0.5;
BrainMaskShade = BrainMask-BrainMask.*alphaVal;
load(fullfile(AnalysisParameters.RefImgPath, sprintf('SessID_%d.mat', SessIDs{MouseNumbers(2)}(1))), 'RefImage');
Model2=Model;BrainMask2=BrainMask;BrainMaskShade2=BrainMaskShade;RefImage2=RefImage;
clear Model BrainMask BrainMaskShade RefImage


for Sess = 1:4
    
    counter = 1;
    for m = MouseNumbers
        for c = PlotConds
            Conditions(counter) = CondLUT.CondID(CondLUT.SessID == SessIDs{m}(Sess) & CondLUT.Cond == c);
            counter = counter+1;
        end
    end
    
    
    %% load those sessions into memory
    clear CondData
    counter = 1;
    for c = Conditions
        load(fullfile(AnalysisParameters.CondWFDataPath, sprintf('CondID_%d.mat', c)), 'Cond_dFF_avg')
        CondData(:,:,:,counter) = Cond_dFF_avg;
        clear Cond_dFF_avg
        counter = counter+1;
    end
    
    
    %% Plot the dFF of this Session
    AnalysisParameters.Timeline = -200:50:550;
    lims = [quantile(CondData(:),0.01) quantile(CondData(:),0.99)];
    lims = [-max(abs(lims)) max(abs(lims))];   
    
    
    %% make a video and store it
    
    videoname = [AnalysisParameters.VideoPath '\' PlotMice{1} '_' PlotMice{2} '_' SessConds{Sess}];
    myVideo = VideoWriter(videoname);
    myVideo.FrameRate = 1;
    open(myVideo)
    for t = 1:length(AnalysisParameters.Timeline)
        fh = figure('visible', 'off','Position', [309          52        1455         888]);
        for x = 1:6
            subplot(2,3,x)
            if x <= 3
                RefImage = RefImage1;
                BrainMask = BrainMask1;
                BrainMaskShade = BrainMaskShade1;
                Model = Model1;
            else
                RefImage = RefImage2;
                BrainMask = BrainMask2;
                BrainMaskShade = BrainMaskShade2;
                Model = Model2;
            end
            if any(any(~isnan(CondData(:,:,t,x))))
                im = imagesc(RefImage);colormap gray;
                im.AlphaData = BrainMask;
                freezeColors
                hold on
                h=imagesc(CondData(:,:,t,x),lims);
                colormap(redblue)
                clb = colorbar;
                clb.Label.String = 'dFF';
                cbfreeze(clb)
                imAlpha = BrainMaskShade;imAlpha(isnan(CondData(:,:,t,x))) = false;
                h.AlphaData = imAlpha;
                plot(Model.AllX,Model.AllY,'k.', 'MarkerSize', 2)
                axis square
                box off
                axis off
                title([PlotCondNames{x} ' ' num2str(AnalysisParameters.Timeline(t)) ' ms'])
                if AnalysisParameters.Timeline(t) >= 0 && AnalysisParameters.Timeline(t) <= 500
                    annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
                end
                hold off
            end
        end
        frame = getframe(fh);
        writeVideo(myVideo,frame);
        close(fh)
    end
    close(myVideo)
    
    
end


end