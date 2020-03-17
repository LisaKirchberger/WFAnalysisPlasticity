clear all
close all
clc

%% set up some variables
storepath = '\\VC2NIN\Mouse_Plasticity\WFimaging\';
rawdatapath = '\\VC2NIN\Mouse_Plasticity\RawData\';
Mouse = 'Bran';
Date = '20191022';
SessID = '1';

Logfilepath = [rawdatapath, Mouse, '\', Mouse, Date, '\', Mouse, SessID, '\', Mouse, SessID];
load(Logfilepath)

if strcmp(Log.Task,'EasyOptoDetection_PassiveMultiLaser')
    Conditions = 1:6;
    CondWords = {'0mW', '0.1mW', '0.5mW', '1mW', '5mW', '10mW'};
elseif strcmp(Log.Task,'EasyOptoDetection_Passive')
    Conditions = 1:4;
    CondWords = {'Opto', 'NoGo', 'Visual', 'Auditory'};
end


PlotFigures = 'off'; % can be 'on' or 'off'

%% load the Allen Brain Model
Allenmodelpath = [storepath Mouse '\brainareamodel.mat'];
load(Allenmodelpath)


%% run through the conditions and show and store movies

for c = Conditions
    
    %% load the WF data, convert and calculate dFF
    
    %load 
    filename = [storepath Mouse '\' Mouse Date '\' Mouse SessID '\' Mouse SessID '_RawData_C' num2str(c) '.mat'];
    load(filename)
    
    %first convert the unit16 conddata matrix into a single and make sureto turn all 0s into NaNs!!!
    % conddata = 400 x 400 x timepoints x trials
    conddata = single(conddata);
    conddata(conddata==0) = NaN;
    xpix = size(conddata,1);
    ypix = size(conddata,2);
    
    
    % Calculate the dFF with a trial specific baseline
    base = single(nanmean(conddata(:,:,timeline>=-350&timeline<0,:),3));
    dFF = (conddata - repmat(base,[1,1,length(timeline),1]))./repmat(base,[1,1,length(timeline),1]);
    
    %% Remove pixels outside of the Allen Brain Model
    throwawayareas = find(cellfun(@isempty,Model.Rnames));
    throwawayareas = [throwawayareas; find(cellfun(@(X) ismember(X,{'OlfactoryBulb','InfCol','SupColSens'}),Model.Rnames))];
    keepareas = 1:length(Model.Rnames);
    keepareas(throwawayareas)=[];
    removepix = true(xpix,ypix);
    for areaid = 1:length(keepareas)
        bounds = Model.Boundaries{keepareas(areaid)};
        for boundid = 1:length(bounds)
            if any(any(bounds{boundid}>xpix*1.5)) 
                bounds{boundid} = round(bounds{boundid}.*AnalysisParameters.ScaleFact);
            end
            removepix(poly2mask(bounds{boundid}(:,1),bounds{boundid}(:,2),xpix,ypix)) = 0;
        end
    end
    
    alphaVal = 0.5;
    removeouterpix = ~removepix;
    removeandshadepix = removeouterpix-removeouterpix.*alphaVal;
    
    %% get and save an image of just the reference image of the brain
    if c == Conditions(1)
        gotimage = 0;
        counter = 1;
        while gotimage == 0
            refImage = squeeze(conddata(:,:,counter,2));
            if sum(isnan(refImage(:))) > 20000
                counter = counter + 1;
            else
                gotimage = 1;
            end
        end
        figure('visible', PlotFigures);im = imagesc(refImage);colormap gray;clb = colorbar; clb.Label.String = 'Fluorescence'; im.AlphaData = removeouterpix; freezeColors; hold on;
        plot(Model.AllX,Model.AllY,'k.'); axis square; box off; axis off
        imname = [storepath Mouse '\' Mouse Date '\' Mouse SessID '\' Mouse SessID '_refImage_map.bmp'];
        saveas(gcf, imname)
        figure('visible', PlotFigures);im = imagesc(refImage);colormap gray;clb = colorbar; clb.Label.String = 'Fluorescence'; axis square; box off; axis off
        imname = [storepath Mouse '\' Mouse Date '\' Mouse SessID '\' Mouse SessID '_refImage.bmp'];
        saveas(gcf, imname)
    end
    
            
    %% average over trials and show a movie
    dFF_avg = nanmean(dFF,4);
    lims = [quantile(dFF_avg(:),0.01) quantile(dFF_avg(:),0.99)];
    lims = [-max(abs(lims)) max(abs(lims))];
    wanted_timeline = timeline(timeline >= -300 & timeline <=1000);
    figure('visible', PlotFigures);
    for t = 1:length(wanted_timeline)
        tp = find(timeline == wanted_timeline(t));
        im = imagesc(refImage);colormap gray;
        %im.AlphaData = removeouterpix;
        freezeColors
        hold on
        h=imagesc(dFF_avg(:,:,tp),lims);
        colormap(redblue)
        clb = colorbar;
        clb.Label.String = 'dFF';
        cbfreeze(clb)
        %h.AlphaData = removeandshadepix;
        plot(Model.AllX,Model.AllY,'k.')
        axis square
        box off
        axis off
        title([CondWords{c} ' ' num2str(timeline(tp)) ' ms'])
        if timeline(tp) == 0
            annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
        elseif timeline(tp) == 1000
            annot.Visible = 'off';
            clear annot
        end
        hold off
        pause(0.3)
    end
    
    
    % make a video and store it
    videoname = [storepath Mouse '\' Mouse Date '\' Mouse SessID '\' Mouse SessID '_AVGVideo_C' num2str(c)];
    myVideo = VideoWriter(videoname);
    myVideo.FrameRate = 5;
    open(myVideo)
    for t = 1:length(wanted_timeline)
        fh = figure('visible', 'off','units','normalized');
        tp = find(timeline == wanted_timeline(t));
        h=imagesc(dFF_avg(:,:,tp),lims);
        colormap(redblue)
        clb = colorbar;
        clb.Label.String = 'dFF';
        hold on
        plot(Model.AllX,Model.AllY,'k.')
        set(h,'AlphaData',removepix==0)
        axis square
        box off
        axis off
        title([CondWords{c} ' ' num2str(timeline(tp)) ' ms'])
        if timeline(tp) >= 0 && timeline(tp) <=1000
            annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
        end
        frame = getframe(fh);
        writeVideo(myVideo,frame);
        close(fh)
    end
    close(myVideo)

    % make a video with the brain underneath and store it 
    videoname = [storepath Mouse '\' Mouse Date '\' Mouse SessID '\' Mouse SessID '_AVGVideo_brain_C' num2str(c)];
    myVideo = VideoWriter(videoname);
    myVideo.FrameRate = 5;
    open(myVideo)
    for t = 1:length(wanted_timeline)
        fh = figure('visible', 'off','units','normalized');
        tp = find(timeline == wanted_timeline(t));
        im = imagesc(refImage);colormap gray;
        im.AlphaData = removeouterpix;
        freezeColors
        hold on
        h=imagesc(dFF_avg(:,:,tp),lims);
        colormap(redblue)
        clb = colorbar;
        clb.Label.String = 'dFF';
        cbfreeze(clb)
        h.AlphaData = removeandshadepix;
        plot(Model.AllX,Model.AllY,'k.')
        axis square
        box off
        axis off
        title([CondWords{c} ' ' num2str(timeline(tp)) ' ms'])
        if timeline(tp) >= 0 && timeline(tp) <=1000
            annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
        end
        frame = getframe(fh);
        writeVideo(myVideo,frame);
        close(fh)
    end
    close(myVideo)
    
    
    %% check if running makes the video crappy
    
    % load the Log file 
    Logfilename = [rawdatapath Mouse '\' Mouse Date '\' Mouse SessID '\' Mouse SessID '.mat'];
    load(Logfilename)
    
    wanted_rundata = -0.5:0.1:1.5; % in seconds from 2 s before stim to 1.5 after
    counter = 1;
    for Trial = find(Log.TrialCond == c)
        RunningTimecourse(counter,:) = interp1(Log.RunningTiming{Trial}, Log.RunningVec{Trial}, wanted_rundata); %#ok<SAGROW>
        RunningMean(counter) = nanmean(RunningTimecourse(counter,:));
        RunningSD(counter) = nanstd(RunningTimecourse(counter,:));
        counter = counter +1;
    end
    
    
    
    %% plot only trials with an absolute running speed below the running threshold
    SpeedThres = 0.05;
    wantedTrials = abs(RunningMean) < SpeedThres;
    fprintf('removed %d out of %d Trials \n', sum(~wantedTrials), length(wantedTrials))
    dFF_avg = nanmean(dFF(:,:,:,wantedTrials),4);
    lims = [quantile(dFF_avg(:),0.01) quantile(dFF_avg(:),0.99)];
    lims = [-max(abs(lims)) max(abs(lims))];
    wanted_timeline = timeline(timeline >= -300 & timeline <=1000);
    figure('visible', PlotFigures, 'name', 'no running');
    for t = 1:length(wanted_timeline)
        tp = find(timeline == wanted_timeline(t));
        im = imagesc(refImage);colormap gray;
        im.AlphaData = removeouterpix;
        freezeColors
        hold on
        h=imagesc(dFF_avg(:,:,tp),lims);
        colormap(redblue)
        clb = colorbar;
        clb.Label.String = 'dFF';
        cbfreeze(clb)
        h.AlphaData = removeandshadepix;
        plot(Model.AllX,Model.AllY,'k.')
        axis square
        box off
        axis off
        title([CondWords{c} ' ' num2str(timeline(tp)) ' ms'])
        if timeline(tp) == 0
            annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
        elseif timeline(tp) == 1000
            annot.Visible = 'off';
            clear annot
        end
        hold off
        pause(0.3)
    end
    
    
    
    %% plot only trials with an absolute running speed below the running threshold
    SDThres = 0.2;
    wantedTrials = abs(RunningSD) < SDThres;
    fprintf(' removed %d out of %d Trials \n %d percent Trials removed \n', sum(~wantedTrials), length(wantedTrials), round(sum(~wantedTrials)/length(wantedTrials)*100))
    dFF_avg = nanmean(dFF(:,:,:,wantedTrials),4);
    lims = [quantile(dFF_avg(:),0.01) quantile(dFF_avg(:),0.99)];
    lims = [-max(abs(lims)) max(abs(lims))];
    wanted_timeline = timeline(timeline >= -300 & timeline <=1000);
    figure('visible', PlotFigures, 'name', 'no running onset/offset');
    for t = 1:length(wanted_timeline)
        tp = find(timeline == wanted_timeline(t));
        im = imagesc(refImage);colormap gray;
        im.AlphaData = removeouterpix;
        freezeColors
        hold on
        h=imagesc(dFF_avg(:,:,tp),lims);
        colormap(redblue)
        clb = colorbar;
        clb.Label.String = 'dFF';
        cbfreeze(clb)
        h.AlphaData = removeandshadepix;
        plot(Model.AllX,Model.AllY,'k.')
        axis square
        box off
        axis off
        title([CondWords{c} ' ' num2str(timeline(tp)) ' ms'])
        if timeline(tp) == 0
            annot = annotation('textbox',[.05 .9 0 0],'String','Stimulus ON' ,'FitBoxToText','on', 'EdgeColor', 'red', 'LineWidth', 2);
        elseif timeline(tp) == 1000
            annot.Visible = 'off';
            clear annot
        end
        hold off
        pause(0.3)
    end
    
    
    %% try it with outlier removal
    %tmp_dFF = rmoutliers(dFF,4); %only works with Matlab 2019
    % find the pixels in the brain
    brainpix = logical(removeouterpix);
    braindFF = dFF(brainpix,:,:);
    dFFz = zscore(dFF,0,4);
    
end
