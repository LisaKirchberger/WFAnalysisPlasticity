function createAllenBrainModel_Joe(AllenBrainFilePath, AllenImagesPath, PixelNumX, PixelNumY)

%% Read in the Screenshots of the Allen Brain Map and create masks for each region

AllenImages = dir(fullfile(AllenImagesPath,'*tif'));
Area = cell(length(AllenImages),1);
AreaName = cell(length(AllenImages),1);
for i = 1:length(Area)
    Image = imread(fullfile(AllenImagesPath,AllenImages(i).name));
    TemplateImage = imread(fullfile(AllenImagesPath,'Template\Template.tif'));
    Area_RGB = Image-TemplateImage;
    Area_grey = rgb2gray(Area_RGB);
    Area_mask = logical(Area_grey); Area_mask(1:38,1:38) = 0;
    Area{i}= Area_mask;
    rescaledArea = strsplit(AllenImages(i).name, '.tif');
    AreaName{i} = rescaledArea{1};
end


%% Rescale the masks to the size of our widefield images (so they have the same pixel numbers)

RescaleX = (PixelNumX)/size(Image,1);
RescaleY = (PixelNumY)/size(Image,2);
Boundary = cell(length(Area),1);
for i = 1:length(Area)
    % determine the boundary around the area
    Boundary{i} = bwboundaries(Area{i}); 
    if length(Boundary{i}) > 5
        Area{i} = bwmorph(Area{i},'branchpoints',5);
        Boundary{i} = bwboundaries(Area{i});
    end
    % rescale the boundary & area to fit the widefield images
    rescaledArea = false(PixelNumX,PixelNumY);
    for j = 1:length(Boundary{i})
        Boundary{i}{j}(:,2) = round(Boundary{i}{j}(:,2) .* RescaleX);
        Boundary{i}{j}(:,1) = round(Boundary{i}{j}(:,1) .* RescaleY);
        rescaledArea(poly2mask(Boundary{i}{j}(:,2),Boundary{i}{j}(:,1),PixelNumX,PixelNumY))=1;
    end
    Area{i} = rescaledArea;
end


%% reshape Boundary so that it is more easy to plot & make vector with all boundaries called AllX and AllY

AllX = [];AllY = [];
for n = 1:length(Boundary)
    for k = 1:length(Boundary{n})
        X = Boundary{n}{k}(:,2);
        Y = Boundary{n}{k}(:,1);
        Boundary{n}{k} = [];
        Boundary{n}{k}(:,1) = X;
        Boundary{n}{k}(:,2) = Y;
        AllX = [AllX;X]; %#ok<*AGROW>
        AllY = [AllY;Y];
    end
end

[AllX,ind] = sort(AllX);
AllY = AllY(ind);

%% add additional Areas

additionalAreas = {'VIS', 'SS', 'AUD', 'MO', 'RSP'};
for addA = 1:length(additionalAreas)
    wantedAreas = find(~cellfun(@isempty, regexp(AreaName, additionalAreas{addA}, 'match') ));
    Boundaries = [];
    for a = wantedAreas'
        Boundaries = [Boundaries; Boundary{a}];
    end
    myMask = false(PixelNumX,PixelNumY);
    for b = 1:length(Boundaries)
        myMask(poly2mask(Boundaries{b}(:,1),Boundaries{b}(:,2),PixelNumX,PixelNumY)) = true;
    end
    AreaNum = size(AreaName,1);
    AreaName{AreaNum+1} = additionalAreas{addA};
    Boundary{AreaNum+1} = Boundaries;
    Area{AreaNum+1} = myMask;
end


%% fill the model & save it

Model = [];
Model.AreaName = AreaName;
Model.Boundary = Boundary;
Model.AreaMask = Area;
Model.AllX = AllX;
Model.AllY = AllY;
Model.Bregma = [169 200]; %estimated values x and y
save(AllenBrainFilePath,'Model')

end