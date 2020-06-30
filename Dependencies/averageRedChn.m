%% Select the folder containing the images from the red Channel and load them all in

FolderPath = uigetdir('\\vc2nin\Mouse_Plasticity\RawData\');
MatlabPath = 'D:\GitHub\WFAnalysisPlasticity\Dependencies';
tmp = strsplit(FolderPath, '\');
Mouse = tmp{5};
cd(FolderPath)
ImagePaths = dir('*.tiff');


%% get AnalysisParameters if it doesn't exist

if ~exist('AnalysisParameters','var')
    cd(MatlabPath)
    AnalysisParameters = getFixedParameters(AnalysisParameters);
    cd(FolderPath)
end


%% get the Alignment data for this session

cd ..
if ~exist('AligningResults.mat','file')
   cd ..
   folders = dir(); folders = folders([folders.isdir]); folders = folders(~ismember({folders.name}, {'.', '..'}));
   cd(folders(1).name)
   AligningFile = fullfile(pwd, 'AligningResults.mat');
   cd(FolderPath)
   cd ..
   copyfile(AligningFile)
end
load('AligningResults.mat')


%% load in reference image (pRF image)

load(fullfile(AnalysisParameters.pRFMappingDir,Mouse,'RefImg')) 
refImage = uint16(brain);
clear brain intbrain


%% read in images and average them

ImageNum = size(ImagePaths,1);
Images = NaN(400,400,ImageNum);

for i = 1:ImageNum
    
    Image = imread(fullfile(ImagePaths(i).folder,ImagePaths(i).name), 'tiff');Image = Image(:,:,1);
    regImage = imwarp(Image,TM,'OutputView',imref2d(size(refImage)));
    Images(:,:,i) = imresize(regImage,AnalysisParameters.ScaleFact);
end

avgImage = nanmean(Images,3);
imwrite(uint16(avgImage), 'avgImage_tdTom.tiff', 'TIFF')


%% clean up

cd(MatlabPath)
clearvars -except AnalysisParameters AnalyseDataDets


