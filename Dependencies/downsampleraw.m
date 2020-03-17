%% downsampleraw

% This script takes the 12bit bmp images that come out of the microscope
% and turns them into 16bit images

folders = dir; folders(~cell2mat(extractfield(folders, 'isdir'))) = []; folders = folders(3:end);
for i = 1:length(folders)
    try
        cd(folders(i).name)
    catch
        keyboard
    end
    
    images = dir;
    images = images(3:end);
    if sum(~cellfun(@isempty,(cellfun(@(X) strfind(X,'.tiff'),{images(:).name},'UniformOutput',0)))) == sum(~cellfun(@isempty,(cellfun(@(X) strfind(X,'.bmp'),{images(:).name},'UniformOutput',0))))
        cd ..
        continue
    end
    
    for j = 1:length(images)
        if strcmp(images(j).name(end-3:end), '.bmp')
            try
                M = readrawimage(images(j).name);
            catch
                keyboard
            end
            
            % turn 1600x1600 image into an 800x800 image
            p=2; q=2;
            [m,n]=size(M); %M is the original matrix
            M= sum( reshape(M,p,[]) ,1 );
            M=reshape(M,m/p,[]).'; %Note transpose
            M=sum( reshape(M,q,[]) ,1);
            M=reshape(M,n/q,[]).'; %Note transpose
            
            imwrite(uint16(M), [images(j).name(1:end-3) 'tiff'], 'TIFF')
        end
    end
    cd ..
    
end