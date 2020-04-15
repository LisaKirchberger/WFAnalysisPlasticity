

%% This script aligns a reference brain image to the Allen Brain Map

%% These variables need to be changed!!! 

AllenBrainFolder = 'C:\Users\Joe-S\Documents\Documents\Data\Mesoscope\Analysis parameters';
ReferenceImageFolder = 'C:\Users\Joe-S\Documents\Documents\Data\Mesoscope\Analysis parameters\ReferenceImages'; %you need a reference image for each mouse saved here that you use for the alignment, also look at line 31
AllenBrainFilePath = fullfile(AllenBrainFolder, 'Model.mat'); % this is where it will save the Model 
AllenImagesPath = 'xxxxxx\AllenBrainImages';%put whereever you saved the screenshots from the allen brain atlas here
PixelNumX = 900;
PixelNumY = 1200; 
Mice = {'MouseA', 'MouseB', 'MouseC'};


%% Read in standard images and create Allen Brain Model (if doesn't exist yet)

if ~exist(AllenBrainFilePath, 'file')
    createAllenBrainModel_Joe(AllenBrainFilePath, AllenImagesPath, PixelNumX, PixelNumY)
end


%% Overlay the Allen Brain Model onto each Mouse

for M = 1:length(Mice)
    
    
    Mouse = Mice{M};
    
    % load the reference image for this mouse 
    pRFfile = [ReferenceImageFolder '\' Mouse 'refImage'];
    
    % filename where will save the model for this mouse
    BrainModelFileMouse = fullfile(AllenBrainFolder, [Mouse '_brainareamodel.mat']);

    
    
    %% If the AllenBrainModel does not yet exist or we want to redo the alignment, align the Allen Brain Map to the reference image (manual step!)
    
    if ~exist(BrainModelFileMouse, 'file')
        
        %% Load the general AllenBrainModel and the pRF reference image
        
        load(AllenBrainFilePath) %#ok<*LOAD>
        
        % here you should load in whichever image you want to use for
        % alignment: you should load an image called brain!
        load(pRFfile)
      
        
        
        %% plot the pRF results (or the images you want to align to --> this could also be 1 image instead of 4 like we plot, then only plot h1)
        
        figure('Name', Mouse, 'Units','normalized','Position',[0 0 0.9 0.9])
        imagesc(brain);colormap gray
        
        
        %% plot the Allen Brain Map (not yet aligned) and manually adjust
        
        title('a = left, d = right, s = down, w = up, f/g = xscale down/up, v/b = yscale down/up, k for okay')
        
        h = plot(Model.AllX,Model.AllY,'k.');
        
        okay = 0;
        key = '0';
        
        Model.OrigAllX = Model.AllX;
        Model.OrigAllY = Model.AllY;
        Model.shiftX = 0;
        Model.shiftY = 0;
        Model.scaleX = 1;
        Model.scaleY = 1;
        
        while ~okay
            delete(h)
            h = plot(Model.AllX,Model.AllY,'k.');
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
        
        
        %% Apply the shift to Bregma (!!! I'm not actually sure this Bregma position is correct,...
        ...don't use it for anything! I only use it to split the brain in half down the midline, for that it's accurate)
        
        Model.Bregma(1) = round((Model.Bregma(1) - Model.shiftX) ./ Model.scaleX);
        Model.Bregma(2) = round((Model.Bregma(2) - Model.shiftY) ./ Model.scaleY);
        
        
        %% Apply the shift to the model areas (based on shifted boundaries)
        
        for i = 1:length(Model.AreaMask)
            Mask = false(PixelNumX,PixelNumY);
            for j = 1:length(Model.Boundary{i})
                Mask(poly2mask(Model.Boundary{i}{j}(:,1),Model.Boundary{i}{j}(:,2),PixelNumX,PixelNumY)) = true;
            end
            Model.AreaMask{i} = Mask;
        end
        
        
        %% Make Boundaries & masks for left and right hemisphere
        
        for i = 1:length(Model.Boundary)
            MaskR = false(PixelNumX,PixelNumY);
            MaskL = false(PixelNumX,PixelNumY);
            for j = 1:length(Model.Boundary{i})
                % right hemisphere; all pixels of boundary with y values smaller than the estimation of Bregma (midline)
                wantedBoundaryPixels = Model.Boundary{i}{j}(:,2) <= Model.Bregma(2);
                Model.BoundaryR{i}{j}(:,1) = Model.Boundary{i}{j}(wantedBoundaryPixels,1);
                Model.BoundaryR{i}{j}(:,2) = Model.Boundary{i}{j}(wantedBoundaryPixels,2);
                MaskR(poly2mask(Model.BoundaryR{i}{j}(:,1),Model.BoundaryR{i}{j}(:,2),PixelNumX,PixelNumY)) = true;
                 % left hemisphere; all pixels of boundary with y values larger than the estimation of Bregma (midline)
                wantedBoundaryPixels = Model.Boundary{i}{j}(:,2) >= Model.Bregma(2);
                Model.BoundaryL{i}{j}(:,1) = Model.Boundary{i}{j}(wantedBoundaryPixels,1);
                Model.BoundaryL{i}{j}(:,2) = Model.Boundary{i}{j}(wantedBoundaryPixels,2);
                MaskL(poly2mask(Model.BoundaryL{i}{j}(:,1),Model.BoundaryL{i}{j}(:,2),PixelNumX,PixelNumY)) = true;
            end
            Model.AreaMaskR{i} = MaskR;
            Model.AreaMaskL{i} = MaskL;
        end
        
        
        %% save the Allen Brain Model for this mouse
        
        save(BrainModelFileMouse,'Model')
        % and save the figure
        BrainModelFigFile =  fullfile(AllenBrainFolder, [Mouse '_AlignmentPlot']);
        saveas(gcf,BrainModelFigFile,'fig')
        
        close all
        
    end
    
end

