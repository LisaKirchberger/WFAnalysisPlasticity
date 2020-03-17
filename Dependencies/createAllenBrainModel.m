function createAllenBrainModel(AnalysisParameters)


folder = fullfile(AnalysisParameters.AllenBrainModelDir, 'AllenBrainImages');

%First screenshot is whole brain, all others are regions
listscrshts = dir(fullfile(folder,'*tif'));

Region =cell(length(listscrshts),1);
Rnames = Region;
for i = 1:length(Region)
    filename = listscrshts(i).name; 
    A = imread(fullfile(folder,filename));
    B = imread(fullfile(folder,'Template\Template.tif'));
    C_RGB = A-B;
    C_GRAY = rgb2gray(C_RGB);
    C_BW = logical(C_GRAY);
    C_BW(1:38,1:38) = 0;
    Region{i}=C_BW;
    tmp = strsplit(filename, '.tif');
    Rnames{i} = tmp{1};
end


xpix = size(A,1);
ypix = size(A,2);

RescaleX = (800*AnalysisParameters.ScaleFact)/xpix;
RescaleY = (800*AnalysisParameters.ScaleFact)/ypix;


Boundary=[];
RegionNew = cell(length(Region),1);
for i = 1:length(Region)
    Boundary{i} = bwboundaries(Region{i});  %#ok<*AGROW>
    if length(Boundary{i}) > 5
        Region{i} = bwmorph(Region{i},'branchpoints',5);
    end
    Boundary{i} = bwboundaries(Region{i}); 
    tmp = false(round(xpix*RescaleX),round(ypix*RescaleY));
    for j = 1:length(Boundary{i})
        Boundary{i}{j}(:,2) = round(Boundary{i}{j}(:,2) .* RescaleX);
        Boundary{i}{j}(:,1) = round(Boundary{i}{j}(:,1) .* RescaleY);
        tmp(poly2mask(Boundary{i}{j}(:,2),Boundary{i}{j}(:,1),round(xpix.*RescaleX),round(ypix.*RescaleY)))=1;
    end
    RegionNew{i} = tmp;
    
end
Region = RegionNew;
clear RegionNew
xpix = round(xpix.*RescaleX);
ypix = round(ypix.*RescaleY);
cortex = zeros(xpix,ypix);

for i = 1:length(Region)
    cortex = cortex+Region{i};
end
figure;imagesc(cortex);axis square;colormap gray;set(gca,'TickDir','out')


Black = zeros(xpix,ypix);
imshow(Black);
AllX = [];AllY = [];
hold on
for n = 1:length(Boundary)
    for k=1:length(Boundary{n})
        X = Boundary{n}{k}(:,2);
        Y = Boundary{n}{k}(:,1);
        NewBoundary{n}{k}(:,1) = X; 
        NewBoundary{n}{k}(:,2) = Y; 
        
        plot(X,Y,'w','Linewidth',1)
        AllX = [AllX;X]; 
        AllY = [AllY;Y]; 
    end
end
hold off

% Estimated Values
BregmaX = 169;
LambdaX = 337;
BregmaY = 200;
LambdaY = 200;

AllX = [AllX;BregmaX;LambdaX];
AllY = [AllY;BregmaY;LambdaY];
[AllX,ind] = sort(AllX);
AllY = AllY(ind);
plot(AllX,AllY,'k.','MarkerSize',5)
hold on
plot(BregmaX,BregmaY,'r*')
plot(LambdaX,LambdaY,'r*')
F = getframe;
I_uint8 = F.cdata(:,:,1);
I_temp = I_uint8/255;
I=logical(I_temp);
imshow(I)

Model = [];
Model.AllX = AllX;
Model.AllY = AllY;
Model.Boundaries = NewBoundary;
Model.Regions = Region;
Model.EmptyCortex = [];
Model.WholeCortex = I;
Model.Lambda = [LambdaX, LambdaY];
Model.Bregma = [BregmaX,BregmaY];
Model.Rnames = Rnames;


save(fullfile(AnalysisParameters.AllenBrainModelDir,'AllenBrainModel'),'Model')
end