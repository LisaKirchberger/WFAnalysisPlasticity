function Rescale16bit_LK(StorePath)

RawDataDir = cd;
folders = dir; folders(~cell2mat(extractfield(folders, 'isdir'))) = []; folders = folders(3:end);
max16bit = 2^16-1;
% !!! careful, noticed that the maximal values coming from the microscope images
% can be up to 4630 instead of 2^12 = 4096, so to be sure we will add a safety margin:
max12bit = 2^12-1 + 1200;
ScaleFactor = max16bit/max12bit;

%% Rescale to full 16 bit and Downsample if wanted (we don't!)

h = waitbar(0,'Rescaling to full 16 bit images...');
for i = 1:length(folders)
    cd(RawDataDir)
    cd(folders(i).name)
    
    images = dir('*tiff');
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

    
    for j = 1:length(images)
        try
            M = imread(images(j).name);
        catch
            warning([images(j).name 'reading problem'])
            warning(ME.message)
            keyboard
        end
        
        M = M.*ScaleFactor;
        
        if ~exist(fullfile(StorePath,folders(i).name), 'dir')
            mkdir(fullfile(StorePath,folders(i).name))
        end
        imwrite(uint16(M),fullfile(StorePath,folders(i).name,[images(j).name]), 'TIFF')
        
    end
    waitbar(i/length(folders))
end
close(h)



