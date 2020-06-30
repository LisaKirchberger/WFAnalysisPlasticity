function extractTdTomFluor(AnalysisParameters)

%% load in the Trial & Condition % Session LUT

load(AnalysisParameters.SessionLUTPath, 'SessionLUT')
Mice = unique(SessionLUT.MouseName);


%% look for all images

for m = 1:length(Mice)
    % go into raw data directory of this mouse
    Mouse = Mice{m};
    cd(fullfile(AnalysisParameters.RawDataDirectory, Mouse))
    
    % check all subfolders for 'avgImage_tdTom.tiff'
    MouseImages = [];
    Dates = [];
    counter = 1;
    foldersDate = dir(); foldersDate = foldersDate([foldersDate.isdir]); foldersDate = foldersDate(~ismember({foldersDate.name}, {'.', '..'}));
    for f = 1:size(foldersDate,1)
        cd(fullfile(foldersDate(f).folder, foldersDate(f).name))
        foldersSess = dir(); foldersSess = foldersSess([foldersSess.isdir]); foldersSess = foldersSess(~ismember({foldersSess.name}, {'.', '..'}));
        for fS = 1:size(foldersSess,1)
            cd(fullfile(foldersSess(fS).folder, foldersSess(fS).name))
            if exist('avgImage_tdTom.tiff', 'file')
                MouseImages{counter} = fullfile(foldersSess(fS).folder, foldersSess(fS).name, 'avgImage_tdTom.tiff');
                Dates{counter} = foldersSess(fS).folder(end-7:end);
                counter = counter + 1;
            end
        end
    end
    cd(fullfile(AnalysisParameters.RawDataDirectory, Mouse))
    
    if isempty(MouseImages)
        fprintf('no tdTomato images for mouse %s\n', Mouse)
        continue
    end
    
    % check if a ROI has been selected for this mouse
    if ~exist('TdTom_ROI.mat', 'file')
        % load in the first image and select ROI, need MATLAB 2019 or later for this!! 
        if verLessThan('matlab','9.5')
            disp('need a newer version of MATLAB for ROI selection')
            keyboard
        end
        Im1 = imread(MouseImages{1}, 'tiff');
        figure
        imshow(Im1,[]);set(gcf,'Position', [907 105 1008 892]),
        title('draw ellipse around tdTomato expression')
        ROI = drawellipse('Color', 'r');
        menu('Click when done','Happy');
        ROI_mask = createMask(ROI);
        save('TdTom_ROI.mat', 'ROI', 'ROI_mask')
        clear Im1 ROI ROI_mask ; close(gcf)
    end
    
    load('TdTom_ROI.mat', 'ROI', 'ROI_mask')
    
    figure
    suptitle(Mouse)
    for i = 1: length(MouseImages)
        Image = imread(MouseImages{i}, 'tiff');
        AxesHandle(i)=subplot(1,length(MouseImages)+1,i);
        imagesc(Image), colormap gray, axis square, set(gcf,'Position', [907 105 1008 892])
        drawellipse('Center', ROI.Center, 'SemiAxes', ROI.SemiAxes, 'Color', 'k', 'StripeColor', 'r','InteractionsAllowed', 'none');
        title(Dates{i})
        ROIData = Image(ROI_mask);
        mROIData(i) = nanmean(ROIData);
    end
    allCLim = get(AxesHandle, {'CLim'});
    allCLim = cat(2, allCLim{:});
    set(AxesHandle, 'CLim', [min(allCLim), max(allCLim)]);
    subplot(1,length(MouseImages)+1,length(MouseImages)+1)
    plot(1:length(MouseImages), mROIData, 'k'),box off,set(gca,'TickDir','out'),axis square
    xticks(1:1:length(MouseImages)),xticklabels(Dates),xtickangle(45),xlim([0 length(MouseImages)+1]),ylim([min(mROIData)-100 max(mROIData)+100])
    set(gcf, 'Position', [671 572 1244 425])
    
    saveas(gcf, fullfile(AnalysisParameters.TaskDataPath, 'TdTomato', [Mouse, '_tdTomatoExtracted']), 'jpeg')
    close(gcf), clear AxesHandle

end


end