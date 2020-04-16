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
            ArrowPos.V1(m,:) = [287.1328 316.91];
            ArrowPos.PPC(m,:)= [263.4442 277.6574];
        case 'Hodor'
            wantedSessions = {'Hodor_20191022_B1', 'Hodor_20191127_B3', 'Hodor_20191211_B2', 'Hodor_20191218_B2'};
            LearningMouse(m) = true;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos.V1(m,:) = [291.1061 303.8333];
            ArrowPos.PPC(m,:)= [256.5606 269.2879];
        case 'Irri'
            wantedSessions = {'Irri_20200127_B1', 'Irri_20200128_B2', 'Irri_20200211_B2', 'Irri_20200225_B2'};
            LearningMouse(m) = false;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos.V1(m,:) = [317.7727 300.8030];
            ArrowPos.PPC(m,:)= [288.0758 268.0758];
        case 'Jon'
            wantedSessions = {'Jon_20200127_B1', 'Jon_20200129_B2', 'Jon_20200212_B2', 'Jon_20200219_B2'};
            LearningMouse(m) = false;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos.V1(m,:) = [290.5000 291.1061];
            ArrowPos.PPC(m,:)= [251.7121 256.5606];
        case 'Lysa'
            % not enough data yet
            continue
            wantedSessions = {'Lysa_20200124_B4'};
            LearningMouse(m) = true;
            for s = 1:length(wantedSessions)
                SessIDs{m}(s) = SessionLUT.SessID( strcmp(SessionLUT.LogfileName, wantedSessions{s} )  ); %#ok<*AGROW>
            end
            ArrowPos.V1(m,:) = [NaN NaN];
            ArrowPos.PPC(m,:)= [NaN NaN];
    end
end


%% create an image that is very crisp so can see the injection site

for m = 1:length(SessIDs)
    Mouse = Mice{m};
    if any(isnan(ArrowPos.V1(m,:)))
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

%% make a video with an arrow pointing at the injection site 1 video per mouse

pickedCond = 5;

for m = 1:length(SessIDs)
    
    Mouse = Mice{m};
    Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
    load(Allenmodelpath, 'Model')
    BrainBoundary = [Model.Boundary{strcmp(Model.AreaName, 'CTXpl')}; Model.Boundary{strcmp(Model.AreaName, 'SCs')}];
    BrainMask = false(AnalysisParameters.Pix,AnalysisParameters.Pix);
    for b = 1:length(BrainBoundary)
        BrainMask(poly2mask(BrainBoundary{b}(:,1),BrainBoundary{b}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = true;
    end
    alphaVal = 0.5;
    BrainMaskShade = BrainMask-BrainMask.*alphaVal;
    load(fullfile(AnalysisParameters.RefImgPath, sprintf('SessID_%d.mat', SessIDs{m}(1))), 'RefImage');
    
    c = CondLUT.CondID(CondLUT.SessID == SessIDs{m}(4) & CondLUT.Cond == pickedCond);
    load(fullfile(AnalysisParameters.CondWFDataPath, sprintf('CondID_%d.mat', c)), 'Cond_dFF_avg')
    
    %% Plot the dFF of this Session
    
    lims = [quantile(Cond_dFF_avg(:),0.01) quantile(Cond_dFF_avg(:),0.99)];
    lims = [-max(abs(lims)) max(abs(lims))];
    
    
    %% make a video and store it
    
    videoname = [AnalysisParameters.VideoPath '\' Mouse '_' num2str(c) '_withArrow'];
    myVideo = VideoWriter(videoname);
    myVideo.FrameRate = 5;
    open(myVideo)
    for t = 1:length(AnalysisParameters.Timeline)
        if any(any(~isnan(Cond_dFF_avg(:,:,t))))
            fh = figure('visible', 'off','units','normalized');
            im = imagesc(RefImage);colormap gray;
            im.AlphaData = BrainMask;
            freezeColors
            hold on
            h=imagesc(Cond_dFF_avg(:,:,t),lims);
            colormap(redblue)
            clb = colorbar;
            clb.Label.String = 'dFF';
            cbfreeze(clb)
            imAlpha = BrainMaskShade;imAlpha(isnan(Cond_dFF_avg(:,:,t))) = false;
            h.AlphaData = imAlpha;
            plot(Model.AllX,Model.AllY,'k.', 'MarkerSize', 1)
            plot(ArrowPos.V1(m,1),ArrowPos.V1(m,2),'b*')
            plot(ArrowPos.PPC(m,1),ArrowPos.PPC(m,2),'r*')
            axis square
            box off
            axis off
            title([CondLUT.CondWord{c} ' ' num2str(AnalysisParameters.Timeline(t)) ' ms'])
            if AnalysisParameters.Timeline(t) >= 0 && AnalysisParameters.Timeline(t) <= round(TrialLUT.Stimdur(CondLUT.TrialIDs{c}(1)))*1000
                annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
            end
            frame = getframe(fh);
            writeVideo(myVideo,frame);
            close(fh)
        end
    end
    close(myVideo)
    
    
    
end



end