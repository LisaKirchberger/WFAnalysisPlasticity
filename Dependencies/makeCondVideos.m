function makeCondVideos(AnalyseDataDets,AnalysisParameters)

%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.TrialLUTPath, 'TrialLUT')
load(AnalysisParameters.CondLUTPath, 'CondLUT')
load(AnalysisParameters.SessionLUTPath, 'SessionLUT')

% change some fields of TrialLUT
if ischar(TrialLUT.Logfile_name)
    TrialLUT.Logfile_name = cellstr(TrialLUT.Logfile_name);
end


%% go through the wanted Sessions and make the videos

for s = AnalyseDataDets.SessID
    
    %% Parameters
    Mouse = char(SessionLUT.MouseName(s));
    LogName = char(SessionLUT.LogfileName(s));
    Conditions = CondLUT.CondID(CondLUT.SessID == s);
    
    
    %% load the Allen Brain Model
    
    Allenmodelpath = [AnalysisParameters.AllenBrainModelDir '\' Mouse '_brainareamodel.mat'];
    load(Allenmodelpath, 'Model')
    
    
    %% Remove pixels outside of the Allen Brain Model
    
    BrainBoundary = [Model.Boundary{strcmp(Model.AreaName, 'CTXpl')}; Model.Boundary{strcmp(Model.AreaName, 'SCs')}];
    BrainMask = false(AnalysisParameters.Pix,AnalysisParameters.Pix);
    for b = 1:length(BrainBoundary)
        BrainMask(poly2mask(BrainBoundary{b}(:,1),BrainBoundary{b}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = true;
    end
    alphaVal = 0.5;
    BrainMaskShade = BrainMask-BrainMask.*alphaVal;
    
    
    %% get a reference image from this Session to plot underneath
    
    load(fullfile(AnalysisParameters.RefImgPath, sprintf('SessID_%d.mat', s)), 'RefImage');
    
    for c = Conditions'
        
        %% Load the Condition Data
        load(fullfile(AnalysisParameters.CondWFDataPath, sprintf('CondID_%d.mat', c)), 'Cond_dFF_avg')
        
        
        %% Plot the average dFF of this condition
        
        lims = [quantile(Cond_dFF_avg(:),0.01) quantile(Cond_dFF_avg(:),0.99)];
        lims = [-max(abs(lims)) max(abs(lims))];
        if strcmp(AnalysisParameters.PlotFigures, 'on')
            figure('visible', AnalysisParameters.PlotFigures, 'Position', [ -576   692   560   420]);
            for t = 1:length(AnalysisParameters.Timeline)
                if any(any(~isnan(Cond_dFF_avg(:,:,t))))
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
                    plot(Model.AllX,Model.AllY,'k.', 'MarkerSize', 2)
                    axis square
                    box off
                    axis off
                    title([CondLUT.CondWord{c} ' ' num2str(AnalysisParameters.Timeline(t)) ' ms'])
                    if AnalysisParameters.Timeline(t) == 0
                        annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
                    elseif AnalysisParameters.Timeline(t) >= round(TrialLUT.Stimdur(CondLUT.TrialIDs{c}(1)))*1000
                        annot.Visible = 'off';
                        clear annot
                    end
                    hold off
                    pause(0.3)
                end
            end
        end
        
        
        %% make a video and store it
        
        videoname = [AnalysisParameters.VideoPath '\C' num2str(c) '_' LogName '_' CondLUT.CondWord{c}];
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
                plot(Model.AllX,Model.AllY,'k.', 'MarkerSize', 2)
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




end
