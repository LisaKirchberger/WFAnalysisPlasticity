function alignAllenBrainMap(AnalyseDataDets,AnalysisParameters)

%% This script aligns a reference brain image to the Allen Brain Map


%% Read in standard images and create Allen Brain Model (if doesn't exist yet)

if ~exist(fullfile(AnalysisParameters.AllenBrainModelDir,'AllenBrainModel.mat'), 'file')
    createAllenBrainModel(AnalysisParameters)
end


%% Overlay the Allen Brain Model onto each Mouse

for M = 1:size(AnalysisParameters.Mice,2)
    
    RedoAlignment_Mouse = AnalysisParameters.RedoAllenBrainAlignment;
    Mouse = AnalysisParameters.Mice{M};
    
    
    %% Check if Alignment Data is already present
    
    if ~any(strcmp(AnalyseDataDets.Mouse, Mouse))
        continue
    end
    
    BrainModelFileMouse = fullfile(AnalysisParameters.AllenBrainModelDir, [Mouse '_brainareamodel.mat']);
    
    %% If Data is already present, just show it
    
    if exist(BrainModelFileMouse, 'file') && RedoAlignment_Mouse == 0
        
        %% Load in mouse specific AllenBrainModel and the pRF reference image
        
        load(BrainModelFileMouse)
        pRFfile = fullfile(AnalysisParameters.pRFMappingDir,Mouse,'pRFmaps');
        load(pRFfile)
        
        
        %% Adjust pRF output
        
        %Interpolate and threshold using the r value
        rthresh = 0.65;
        % Azimuth
        AZIit = AZIi;
        AZIit(CRFi<rthresh) = NaN;
        % Elevation
        ELEit = ELEi;
        ELEit(CRFi<rthresh) = NaN;
        % pRF
        PRFit = PRFi;
        PRFit(CRFi<rthresh) = NaN;
        % FSM
        SIGNMAPp = out.SIGNMAPp;
        SIGNMAPp(~SIGNMAPp) = NaN;
        SIGNMAPp(CRFi<rthresh) = NaN;
        
        
        %% Adjust sizes of reference image and pRF output
        
        if size(AZIit,2) ~= size(brain,1)
            AZIit = cat(2,nan(size(AZIit,1),size(brain,2)-size(AZIit,2)),AZIit);
            ELEit = cat(2,nan(size(ELEit,1),size(brain,2)-size(ELEit,2)),ELEit);
            PRFit = cat(2,nan(size(PRFit,1),size(brain,2)-size(PRFit,2)),PRFit);
            SIGNMAPp = cat(2,nan(size(SIGNMAPp,1),size(brain,2)-size(SIGNMAPp,2)),SIGNMAPp);
        end
        
        if size(AZIit,1) ~= size(brain,1)
            AZIit = imresize(AZIit,AnalysisParameters.ScaleFact);
            ELEit = imresize(ELEit,AnalysisParameters.ScaleFact);
            PRFit = imresize(PRFit,AnalysisParameters.ScaleFact);
            SIGNMAPp = imresize(SIGNMAPp,AnalysisParameters.ScaleFact);
            out.SIGNMAPt = imresize(out.SIGNMAPt,AnalysisParameters.ScaleFact);
            sq2brain = 1:(800*AnalysisParameters.ScaleFact)*(800*AnalysisParameters.ScaleFact);
        end
        
        
        %% plot the pRF results with the Allen Brain Map
        
        figure('Name', Mouse, 'Units','normalized','Position',[0 0 0.9 0.9], 'visible', AnalysisParameters.PlotFigures)
        suptitle(Mouse)
        h1 = subplot(3,4,1);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(AZIit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h2 = subplot(3,4,5);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(ELEit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h3 = subplot(3,4,9);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(PRFit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h4 = subplot(3,4,[2 3 4 6 7 8 10 11 12]);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(out.SIGNMAPp,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        
        if exist('Allen','var')
            subplot(h1),h5 = scatter(Allen(:,1),Allen(:,2),'k.');axis square %#ok<*NASGU>
            subplot(h2),h6 = scatter(Allen(:,1),Allen(:,2),'k.');axis square
            subplot(h3),h7 = scatter(Allen(:,1),Allen(:,2),'k.');axis square
            subplot(h4),h8 = scatter(Allen(:,1),Allen(:,2),'k.');axis square
        else
            RedoAlignment_Mouse = 1;
        end
    end
    
    
    
    %% If the AllenBrainModel does not yet exist or we want to redo the alignment, align the Allen Brain Map to the reference image (manual step!)
    
    if ~exist(BrainModelFileMouse, 'file') || RedoAlignment_Mouse
        
        %% Load the general AllenBrainModel and the pRF reference image
        
        load(fullfile(AnalysisParameters.AllenBrainModelDir,'AllenBrainModel.mat'))
        pRFfile = fullfile(AnalysisParameters.pRFMappingDir,Mouse,'pRFmaps');
        load(pRFfile)
        
        [LambdaMouse,BregmaMouse,allenx,alleny,XScaleold,YScaleold,shiftXold,shiftYold,Model] = getLambdaBregma(uint16(brain),Model,1); %#ok<ASGLU>
        
        %% Adjust pRF output
        
        %Interpolate and threshold using the r value
        rthresh = 0.65;
        % Azimuth
        AZIit = AZIi;
        AZIit(CRFi<rthresh) = NaN;
        % Elevation
        ELEit = ELEi;
        ELEit(CRFi<rthresh) = NaN;
        % pRF
        PRFit = PRFi;
        PRFit(CRFi<rthresh) = NaN;
        % FSM
        SIGNMAPp = out.SIGNMAPp;
        SIGNMAPp(~SIGNMAPp) = NaN;
        SIGNMAPp(CRFi<rthresh) = NaN;
        
        
        %% Adjust sizes of reference image and pRF output
        
        if size(AZIit,2) ~= size(brain,1)
            AZIit = cat(2,nan(size(AZIit,1),size(brain,2)-size(AZIit,2)),AZIit);
            ELEit = cat(2,nan(size(ELEit,1),size(brain,2)-size(ELEit,2)),ELEit);
            PRFit = cat(2,nan(size(PRFit,1),size(brain,2)-size(PRFit,2)),PRFit);
            SIGNMAPp = cat(2,nan(size(SIGNMAPp,1),size(brain,2)-size(SIGNMAPp,2)),SIGNMAPp);
        end
        
        if size(AZIit,1) ~= size(brain,1)
            AZIit = imresize(AZIit,AnalysisParameters.ScaleFact);
            ELEit = imresize(ELEit,AnalysisParameters.ScaleFact);
            PRFit = imresize(PRFit,AnalysisParameters.ScaleFact);
            SIGNMAPp = imresize(SIGNMAPp,AnalysisParameters.ScaleFact);
            out.SIGNMAPt = imresize(out.SIGNMAPt,AnalysisParameters.ScaleFact);
            sq2brain = 1:(800*AnalysisParameters.ScaleFact)*(800*AnalysisParameters.ScaleFact);
        end
        
        %% plot the pRF results with the Allen Brain Map and manually adjust
        
        figure('Name', Mouse, 'Units','normalized','Position',[0 0 0.9 0.9])
        suptitle(Mouse)
        h1 = subplot(3,4,1);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(AZIit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h2 = subplot(3,4,5);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(ELEit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h3 = subplot(3,4,9);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(PRFit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h4 = subplot(3,4,[2 3 4 6 7 8 10 11 12]);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(out.SIGNMAPp,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        
        suptitle('a = left, d = right, s = down, w = up, f/g = xscale down/up, v/b = yscale down/up, k for okay')
        
        OrigAllen = [allenx,alleny];
        Allen =  [allenx,alleny];
        XScale = 1; YScale = 1;
        shiftX = 0; shiftY = 0;
        Allen(:,1) = (OrigAllen(:,1)-shiftX)./XScale;
        Allen(:,2) = (OrigAllen(:,2)-shiftY)./YScale;
        
        subplot(h1),h5 = plot(Allen(:,1),Allen(:,2),'k.');
        subplot(h2),h6 = plot(Allen(:,1),Allen(:,2),'k.');
        subplot(h3),h7 = plot(Allen(:,1),Allen(:,2),'k.');
        subplot(h4),h8 = plot(Allen(:,1),Allen(:,2),'k.');
        
        okay = 0;
        key = '0';
        while ~okay
            
            delete(h5),delete(h6),delete(h7),delete(h8)
            subplot(h1),h5 = plot(Allen(:,1),Allen(:,2),'k.');
            subplot(h2),h6 = plot(Allen(:,1),Allen(:,2),'k.');
            subplot(h3),h7 = plot(Allen(:,1),Allen(:,2),'k.');
            subplot(h4),h8 = plot(Allen(:,1),Allen(:,2),'k.');
            
            if strcmp(key,'d')
                shiftX = shiftX-1;
                key = '0';
            elseif strcmp(key,'a')
                shiftX = shiftX+1;
                key = '0';
            elseif strcmp(key,'w')
                shiftY = shiftY+1;
                key = '0';
            elseif strcmp(key,'s')
                shiftY = shiftY-1;
                key = '0';
            elseif strcmp(key,'f')
                XScale = XScale*1.01;
                key = '0';
            elseif strcmp(key,'g')
                XScale =XScale*0.99;
                key = '0';
            elseif strcmp(key,'v')
                YScale = YScale*1.01;
                key = '0' ;
            elseif strcmp(key,'b')
                YScale = YScale*0.99;
                key = '0';
            elseif strcmp(key,'k')
                okay = 1;
            else
                waitforbuttonpress
                key = get(gcf,'CurrentCharacter');
            end
            
            Allen(:,1) = (OrigAllen(:,1)-shiftX)./XScale;
            Allen(:,2) = (OrigAllen(:,2)-shiftY)./YScale;
        end
        
        disp('Allen Brain Map was successfully aligned')
        
        %% Create the Model
        
        for i = 1:length(Model.Boundaries)
            for j = 1:length(Model.Boundaries{i})
                Model.Boundaries{i}{j}(:,1)=  Model.Boundaries{i}{j}(:,1)/XScaleold - shiftXold;
                Model.Boundaries{i}{j}(:,1)= (Model.Boundaries{i}{j}(:,1)-shiftX)./XScale;
                Model.Boundaries{i}{j}(:,2)=   Model.Boundaries{i}{j}(:,2)/YScaleold - shiftYold;
                Model.Boundaries{i}{j}(:,2)=(Model.Boundaries{i}{j}(:,2)-shiftY)./YScale;
            end
        end
        Model.shiftX = shiftX;
        Model.shiftY = shiftY;
        Model.Xscale = XScale;
        Model.Yscale = YScale;
        
        
        %% Apply shift to Model.regions (based on shifted boundaries)
        
        for i = 1:length(Model.Boundaries)
            Model.Regions{i} = false(800*AnalysisParameters.ScaleFact,800*AnalysisParameters.ScaleFact);
            for j = 1:length(Model.Boundaries{i})
                x=Model.Boundaries{i}{j}(:,1); y = Model.Boundaries{i}{j}(:,2);
                Model.Regions{i} = logical(Model.Regions{i}+poly2mask(y, x, 800*AnalysisParameters.ScaleFact, 800*AnalysisParameters.ScaleFact));
            end
        end
        Model.AllX = Allen(:,1);
        Model.AllY = Allen(:,2);
        
        %% save the Allen Brain Model for this mouse
        
        save(BrainModelFileMouse,'Model','LambdaMouse','BregmaMouse','allenx','alleny','Allen','XScale','YScale','SIGNMAPp','PRFit','ELEit','AZIit')
        BrainModelFigFile =  fullfile(AnalysisParameters.AllenBrainModelDir, [Mouse '_BrainAreaModel']);
        saveas(gcf,BrainModelFigFile,'fig')
        
        close all
        
    end
    
end
end