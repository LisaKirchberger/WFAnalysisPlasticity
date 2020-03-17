function makeVideos_EasyOptoDetection_PassiveMultiLaser(AnalyseDataDets,AnalysisParameters)

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
    
    BrainBoundaries = [Model.Boundaries{strcmp(Model.Rnames, 'CTXpl')} Model.Boundaries{strcmp(Model.Rnames, 'SCs')}];
    removepix = true(AnalysisParameters.Pix,AnalysisParameters.Pix);
    for b = 1:length(BrainBoundaries)
        removepix(poly2mask(BrainBoundaries{b}(:,1),BrainBoundaries{b}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = 0;
    end
    alphaVal = 0.5;
    BrainMask = ~removepix;
    BrainMaskShade = BrainMask-BrainMask.*alphaVal;
    
    
    %% get a reference image from this Session to plot underneath
    
    load(fullfile(AnalysisParameters.RefImgPath, sprintf('SessID_%d.mat', s)), 'RefImage');
    
    for c = 5%Conditions'
        
        %% Load the Condition Data
        load(fullfile(AnalysisParameters.CondWFDataPath, sprintf('CondID_%d.mat', c)), 'Cond_dFF_avg')
        
        
        %% average over trials and show a movie
        
        lims = [quantile(Cond_dFF_avg(:),0.01) quantile(Cond_dFF_avg(:),0.99)];
        lims = [-max(abs(lims)) max(abs(lims))];
        if strcmp(AnalysisParameters.PlotFigures, 'on')
            figure('visible', AnalysisParameters.PlotFigures, 'Position', [ -576   692   560   420]);
            for t = 1:length(AnalysisParameters.Timeline)
                im = imagesc(RefImage);colormap gray;
                im.AlphaData = BrainMask;
                freezeColors
                hold on
                h=imagesc(Cond_dFF_avg(:,:,t),lims);
                colormap(redblue)
                clb = colorbar;
                clb.Label.String = 'dFF';
                cbfreeze(clb)
                h.AlphaData = BrainMaskShade;
                plot(Model.AllX,Model.AllY,'k.')
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
                pause%pause(0.3)
            end
        end
        
        
        %% make a video and store it
        
        videoname = [AnalysisParameters.VideoPath '\' LogName '_' CondLUT.CondWord{c}];
        myVideo = VideoWriter(videoname);
        myVideo.FrameRate = 5;
        open(myVideo)
        for t = 1:length(AnalysisParameters.Timeline)
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
            h.AlphaData = BrainMaskShade;
            plot(Model.AllX,Model.AllY,'k.')
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
        close(myVideo)
        
        
    end
    
end




end
