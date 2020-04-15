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
    if ~any(strcmp(AnalyseDataDets.Mouse, Mouse))
        continue
    end
    BrainModelFileMouse = fullfile(AnalysisParameters.AllenBrainModelDir, [Mouse '_brainareamodel.mat']);

    
    
    
    %% If Data is already present, just show it
    
    if exist(BrainModelFileMouse, 'file') && RedoAlignment_Mouse == 0 && strcmp(AnalysisParameters.PlotFigures, 'on')
        
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
            sq2brain = 1:AnalysisParameters.Pix*AnalysisParameters.Pix;
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
        
        load(fullfile(AnalysisParameters.AllenBrainModelDir,'AllenBrainModel.mat')) %#ok<*LOAD>
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
            sq2brain = 1:AnalysisParameters.Pix*AnalysisParameters.Pix;
        end
        
        %% plot the pRF results 
        
        figure('Name', Mouse, 'Units','normalized','Position',[0 0 0.9 0.9])
        suptitle(Mouse)
        h1 = subplot(3,4,1);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(AZIit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h2 = subplot(3,4,5);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(ELEit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h3 = subplot(3,4,9);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(PRFit,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        h4 = subplot(3,4,[2 3 4 6 7 8 10 11 12]);imagesc(brain); colormap('gray'); freezeColors; colormap('jet'); hold on; tmp = imgaussfilt(out.SIGNMAPp,2,'FilterDomain','spatial'); h = imagesc(tmp,[quantile(tmp(~isnan(tmp)),0.01) quantile(tmp(~isnan(tmp)),0.99)]); set(h,'AlphaData',~isnan(imgaussfilt(AZIit,2,'FilterDomain','spatial')));axis square
        
        
        %% plot the Allen Brain Map and manually adjust
        
        suptitle('a = left, d = right, s = down, w = up, f/g = xscale down/up, v/b = yscale down/up, k for okay')
        
        subplot(h1),h5 = plot(Model.AllX,Model.AllY,'k.');
        subplot(h2),h6 = plot(Model.AllX,Model.AllY,'k.');
        subplot(h3),h7 = plot(Model.AllX,Model.AllY,'k.');
        subplot(h4),h8 = plot(Model.AllX,Model.AllY,'k.');
        
        okay = 0;
        key = '0';
        
        Model.OrigAllX = Model.AllX;
        Model.OrigAllY = Model.AllY;
        Model.shiftX = 0;
        Model.shiftY = 0;
        Model.scaleX = 1;
        Model.scaleY = 1;
        
        while ~okay
            delete(h5),delete(h6),delete(h7),delete(h8)
            subplot(h1),h5 = plot(Model.AllX,Model.AllY,'k.');
            subplot(h2),h6 = plot(Model.AllX,Model.AllY,'k.');
            subplot(h3),h7 = plot(Model.AllX,Model.AllY,'k.');
            subplot(h4),h8 = plot(Model.AllX,Model.AllY,'k.');
            if strcmp(key,'d')
                Model.shiftX = Model.shiftX-1;
                key = '0';
            elseif strcmp(key,'a')
                Model.shiftX = Model.shiftX+1;
                key = '0';
            elseif strcmp(key,'w')
                Model.shiftY = Model.shiftY+1;
                key = '0';
            elseif strcmp(key,'s')
                Model.shiftY = Model.shiftY-1;
                key = '0';
            elseif strcmp(key,'f')
                Model.scaleX = Model.scaleX*1.01;
                key = '0';
            elseif strcmp(key,'g')
                Model.scaleX =Model.scaleX*0.99;
                key = '0';
            elseif strcmp(key,'v')
                Model.scaleY = Model.scaleY*1.01;
                key = '0' ;
            elseif strcmp(key,'b')
                Model.scaleY = Model.scaleY*0.99;
                key = '0';
            elseif strcmp(key,'k')
                okay = 1;
            else
                waitforbuttonpress
                key = get(gcf,'CurrentCharacter');
            end
            Model.AllX = ( Model.OrigAllX - Model.shiftX)./Model.scaleX;
            Model.AllY = ( Model.OrigAllY - Model.shiftY)./Model.scaleY;
        end
        
        disp('Allen Brain Map was successfully aligned')
        
        
        %% Apply the shift to the model boundaries (shift from the Lambda Bregma alignment + manual shift) 
        
        for i = 1:length(Model.Boundary)
            for j = 1:length(Model.Boundary{i})
                Model.Boundary{i}{j}(:,1)=(Model.Boundary{i}{j}(:,1) - Model.shiftX) ./ Model.scaleX;
                Model.Boundary{i}{j}(:,2)=(Model.Boundary{i}{j}(:,2) - Model.shiftY) ./ Model.scaleY;
            end
        end
        
        
        %% Apply the shift to Bregma
        
        Model.Bregma(1) = round((Model.Bregma(1) - Model.shiftX) ./ Model.scaleX);
        Model.Bregma(2) = round((Model.Bregma(2) - Model.shiftY) ./ Model.scaleY);
        
        
        %% Apply the shift to the model areas (based on shifted boundaries)
        
        for i = 1:length(Model.AreaMask)
            Mask = false(AnalysisParameters.Pix,AnalysisParameters.Pix);
            for j = 1:length(Model.Boundary{i})
                Mask(poly2mask(Model.Boundary{i}{j}(:,1),Model.Boundary{i}{j}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = true;
            end
            Model.AreaMask{i} = Mask;
        end
        
        
        %% Make Boundaries for left and right hemisphere
        
        for i = 1:length(Model.Boundary)
            MaskR = false(AnalysisParameters.Pix,AnalysisParameters.Pix);
            MaskL = false(AnalysisParameters.Pix,AnalysisParameters.Pix);
            for j = 1:length(Model.Boundary{i})
                % right hemisphere; all pixels of boundary with y values smaller than the estimation of Bregma (midline)
                wantedBoundaryPixels = Model.Boundary{i}{j}(:,2) <= Model.Bregma(2);
                Model.BoundaryR{i}{j}(:,1) = Model.Boundary{i}{j}(wantedBoundaryPixels,1);
                Model.BoundaryR{i}{j}(:,2) = Model.Boundary{i}{j}(wantedBoundaryPixels,2);
                MaskR(poly2mask(Model.BoundaryR{i}{j}(:,1),Model.BoundaryR{i}{j}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = true;
                 % left hemisphere; all pixels of boundary with y values larger than the estimation of Bregma (midline)
                wantedBoundaryPixels = Model.Boundary{i}{j}(:,2) >= Model.Bregma(2);
                Model.BoundaryL{i}{j}(:,1) = Model.Boundary{i}{j}(wantedBoundaryPixels,1);
                Model.BoundaryL{i}{j}(:,2) = Model.Boundary{i}{j}(wantedBoundaryPixels,2);
                MaskL(poly2mask(Model.BoundaryL{i}{j}(:,1),Model.BoundaryL{i}{j}(:,2),AnalysisParameters.Pix,AnalysisParameters.Pix)) = true;
            end
            Model.AreaMaskR{i} = MaskR;
            Model.AreaMaskL{i} = MaskL;
        end
        
        
        %% save the Allen Brain Model for this mouse
        
        save(BrainModelFileMouse,'Model','SIGNMAPp','PRFit','ELEit','AZIit')
        BrainModelFigFile =  fullfile(AnalysisParameters.AllenBrainModelDir, [Mouse '_BrainAreaModel']);
        saveas(gcf,BrainModelFigFile,'fig')
        
        close all
        
    end
    
end

cd(AnalysisParameters.ScriptsDir)

end