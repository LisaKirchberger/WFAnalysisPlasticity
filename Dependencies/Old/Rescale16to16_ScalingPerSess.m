function Rescale16to16_LK(StorePath)

RawDataDir = cd;
folders = dir; folders(~cell2mat(extractfield(folders, 'isdir'))) = []; folders = folders(3:end);
Range16bit =1:2^16-1;


%% Loop through folders and load in and rescale images

Values = zeros(1,length(Range16bit));
count = 0;
h = waitbar(0,'Loading in images before rescaling');
for i = 1:length(folders)
    
    cd(RawDataDir)
    if ~exist(folders(i).name, 'dir')
        continue
    end
    cd(folders(i).name)
    images = dir('*tiff');
    
    %% check in case no Tiffs are present, still need to run downsampleraw on bmps
    
    if isempty(images)
        images = dir();images = images(3:end);
        try
            M = readrawimage(images(1).name);
        catch
            try
                M = imread(images(1).name);
            catch
                continue
            end
        end
        if size(M,1)>800
            warning('Images 1600x1600, first use normal downsampling on this data!')
            cd(RawDataDir)
            downsampleraw
            cd(folders(i).name)
            images = dir('*tiff');
        end
    end
    
    
    %% now that Tiffs are present load in 10 and create Histogram of Values
    
    for j = round(linspace(1,length(images),10))
        try
            M = imread(images(j).name);
        catch
            disp('can not read in Tiffs, why???')
            keyboard
        end
        count = count+1;
        Values = Values+histc(double(M(:)),Range16bit)';
    end
    waitbar(i/length(folders))
    
    
end
close(h)


%% Display the Histogram of Values obtained from all these images & refine min max to get full range

HH = figure; bar(Range16bit,Values);box off;set(gca,'TickDir', 'out')
xlims = [find(Values > 0, 1, 'first') find(Values > 0, 1, 'last')];         % find first and last Histogram bin with values that occurred
set(gca,'xlim',xlims)
clipping = 0;
if clipping == 0
    lowlim = xlims(1);
    uplim = xlims(2);
elseif clipping == 1
    lowlim = find(Values > count, 1, 'first');               
    uplim =  find(Values > count, 1, 'last'); 
end
if (uplim-lowlim) > 0.6*max(Range16bit)
    disp('Images already upscaled!')
    return
end
h(1) = line([lowlim,lowlim],get(gca,'ylim'),'Color',[0 0 0],'LineWidth',2);
h(2) = line([uplim,uplim],get(gca,'ylim'),'Color',[0 0 0],'LineWidth',2); %#ok<NASGU>


%% check if the shutter was accidentally closed and should pick a different example image of the brain

foldercounter = 1;
imagecounter = 1;
while length(unique(M)) < (uplim-lowlim)/10
    warning('Trials with low ranges; maybe shutter closed??')
    cd(RawDataDir)
    if ~exist(folders(foldercounter).name, 'dir')
        continue
    end
    cd(folders(foldercounter).name)
    images = dir('*tiff');
    M = imread(images.name(imagecounter));
    imagecounter = imagecounter + 1;
    if imagecounter > length(images)
        foldercounter = foldercounter+1;
    end
end


%% Plot example image of the brain and mark all pixels that are clipped

GG = figure; imagesc(M)
colormap(gray); freezeColors; axis square
mask = zeros(size(M)); mask(M<lowlim) = -1; mask(M>uplim) = 1;
if exist('overlay') %#ok<EXIST>
    delete(overlay) %#ok<NODEF>
end
hold on
overlay = imagesc(mask,[-1 1]);
colormap('default')
set(overlay,'AlphaData',~(mask==0))


%% Save the histogram and the example image of the brain

saveas(HH,fullfile(StorePath,'HistogramFluorescenceVals.bmp'))
saveas(HH,fullfile(StorePath,'HistogramFluorescenceVals.fig'))
saveas(GG,fullfile(StorePath,'BrainProjectionFluorVals.bmp'))
saveas(GG,fullfile(StorePath,'BrainProjectionFluorVals.fig'))


%% Rescale to full 16 bit and Downsample if wanted (we don't!)

DownSRate = 16;
h = waitbar(0,'Rescaling to full 16 bit images...');
for i = 1:length(folders)
    cd(RawDataDir)
    cd(folders(i).name)
    images = dir('*tiff');
    for j = 1:length(images)
        try
            M = imread(images(j).name);
        catch 
            warning([images(j).name 'reading problem'])
            warning(ME.message)
            keyboard
        end
        M(M<lowlim) = lowlim;
        M(M>uplim) = uplim;
        
        if DownSRate == 16
            min16 = 0; max16 = 2^16-1;
            M = (max16-min16)/(uplim-lowlim)*(M-lowlim);
            if ~exist(fullfile(StorePath,folders(i).name), 'dir')
                mkdir(fullfile(StorePath,folders(i).name))
            end
            imwrite(uint16(M),fullfile(StorePath,folders(i).name,[images(j).name]), 'TIFF')
        elseif DownSRate == 8
            min8 = 0; max8 = 2^8-1;
            M = (max8-min8)/(uplim-lowlim)*(M-lowlim);
            imwrite(uint8(M),fullfile(StorePath,folders(i).name,[images(j).name(1:end-4) 'tiff']),'TIFF')
        end
    end
    waitbar(i/length(folders))
end
close(h)



