function createTrialData(AnalyseDataDets,AnalysisParameters)

%% Run through the Sessions that need to be analysed and add the logfiles to the master lookup table and the data into the tall array



for s = 1:size(AnalyseDataDets.SessID,2)
    
    Mouse = AnalyseDataDets.Mouse{s};
    
    
    %% load in newest version of the lookup table and the already processed data and the logfile
    
    load(AnalysisParameters.TrialLUTPath)
    load(AnalyseDataDets.LogfilePath{s})
    
    %% add TrialID as a field in the Logtable
    
    TrialID = size(TrialLUT,1)+1;
    Log_table.TrialID = (TrialID:TrialID+size(Log_table,1)-1)';
    Log_table.SessID = repmat(s,size(Log_table,1),1);
    
    %% Reference Image using the pRF map
    
    if exist(fullfile(AnalysisParameters.pRFMappingDir,Mouse,'RefImg.mat'), 'file')
        load(fullfile(AnalysisParameters.pRFMappingDir,Mouse,'RefImg'))
        refImage = uint16(brain);
        clear brain
    else
        disp('There is no reference image for this mouse!')
        keyboard
    end
    
    
    %% Create a Timeline
    
    if ~isfield(AnalysisParameters, 'Timeline') || isempty(AnalysisParameters.Timeline)
        AnalysisParameters.Timeline = -AnalysisParameters.BaselineTime:Par.Exposure:round(Log_table.Stimdur(1)*1000)+AnalysisParameters.BaselineTime;
    end
    TimeSteps = diff(AnalysisParameters.Timeline);
    nFrames = length(AnalysisParameters.Timeline);
    
    
    %% check out how many Trials there will be and see how big DataTanks need to be
    
    TrialDirs = dir([AnalyseDataDets.DataPath{s}, '\*_*']);TrialDirs = TrialDirs([TrialDirs.isdir]);
    nTrials = max(Log_table.Trial);
    if nTrials ~= size(TrialDirs,1)
        disp('number of Trials in Logfile and recording do not match')
        keyboard
    end
    
    
    %% check in case no Tiffs are present, still need to run downsampleraw on bmps
    
    cd(fullfile(TrialDirs(1).folder, TrialDirs(1).name))
    images = dir('*tiff');
    if isempty(images)
        images = dir();images = images(3:end);
        try
            M = readrawimage(images(1).name);
        catch
            try
                M = imread(images(1).name);
            catch
                keyboard
            end
        end
        if size(M,1)>800
            warning('Images 1600x1600, downsample this data!')
            cd(AnalysisParameters.RawDataDirectory)
            downsampleraw
            cd(fullfile(TrialDirs(1).folder, TrialDirs(1).name))
            images = dir('*tiff');
        end
    end
    
    %% Register an image to the reference image (pRF image)
    
    [optimizer, metric] = imregconfig('multimodal');
    
    if ~exist(fullfile(AnalyseDataDets.DataPath{s}, 'AligningResults.mat'), 'file') || AnalysisParameters.RedoRegistration
        regIm = imread(images(1).name, 'tiff');regIm = regIm(:,:,1);
        TM = imregtform(regIm,refImage,'similarity',optimizer,metric);
        save(fullfile(AnalyseDataDets.DataPath{s}, 'AligningResults.mat'),'TM');
        registerToReferenceImage(regIm,refImage,AnalyseDataDets.DataPath{s}, AnalysisParameters)
    end
    
    load(fullfile(AnalyseDataDets.DataPath{s}, 'AligningResults.mat'));
    cd(AnalyseDataDets.DataPath{s})
    
    
    %% see how big data will be and then start Loop
    [oypix, oxpix, ~] = size(refImage);
    ypix = oypix*AnalysisParameters.ScaleFact;
    xpix = oxpix*AnalysisParameters.ScaleFact;
    
    for t = 1:nTrials
        
        %% Create DataTank & look for the images
        
        TrialData = nan(ypix, xpix, nFrames, 'single');
        
        % find the correct Folder
        myFolder = strcmp({TrialDirs.name}, [Mouse Log.Expnum '_' num2str(t)]);
        cd(fullfile(TrialDirs(t).folder, TrialDirs(myFolder).name))
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
                    keyboard
                end
            end
            if size(M,1)>800
                warning('Images 1600x1600, downsample this data!')
                cd(AnalysisParameters.RawDataDirectory)
                downsampleraw
                cd(fullfile(TrialDirs(t).folder, TrialDirs(t).name))
                images = dir('*tiff');
            end
        end
        
        
        %% go through all images and check the Timing
        
        n = 1;
        for i = 1:length(images)
            if strcmp(images(i).name(12:24),'0000000000000')
                keyboard
            end
            time = datetime(images(i).name(12:24),'InputFormat', 'MMddHHmmssSSS');
            if ~strcmp(images(i).name, 'Thumbs.db') && ~strcmp(images(i).name, '.DS_Store') && ~strcmp(images(i).name,'.') && ~strcmp(images(i).name,'..')
                if n == 1
                    starttime = time;
                end
                frameinfo.Imageidx{t}(n) = str2double(images(i).name(1:4));
                frameinfo.StimOn{t}(n) = str2double(images(i).name(10));
                frameinfo.TimeDiff{t}(n) = milliseconds(time-starttime);
                frameinfo.ImageName{t}{n} = images(i).name;
                n = n + 1;
            end
        end
        startidx = find(frameinfo.StimOn{t}, 1);
        if isempty(startidx)
            keyboard
        end
        frameinfo.TimeLine{t} = frameinfo.TimeDiff{t} - (startidx-1) * TimeSteps(1);
        
        
        %% go through the Timeline, look if there is image taken at this time and put it at correct place of Trialdata
        
        for x = 1:length(AnalysisParameters.Timeline)
            tdiff = abs(frameinfo.TimeLine{t} - AnalysisParameters.Timeline(x));
            if min(tdiff) < AnalysisParameters.Exposure/2
                Frameidx = find(tdiff == min(tdiff), 1);
                Image = imread(images(Frameidx).name, 'tiff');Image = Image(:,:,1);
                regImage = imwarp(Image,TM,'OutputView',imref2d(size(refImage)));
                if AnalysisParameters.SmoothFact>0
                    regImage = imgaussfilt(regImage,AnalysisParameters.SmoothFact);
                end
                TrialData(:,:,x) = imresize(regImage,AnalysisParameters.ScaleFact);
            end
        end 
        
        %% save the data of this Trial

        fileName = fullfile(AnalysisParameters.TrialWFDataPath, sprintf('TrialID_%d.mat', TrialID));
        save(fileName, 'TrialData')
        clear TrialData
        
        TrialLUT = cat(1,TrialLUT,Log_table(t,:));
        save(AnalysisParameters.TrialLUTPath, 'TrialLUT')
        
        TrialID = TrialID + 1;
        
    end %Trials
    
    clear frameinfo    
    
end %Sessions

cd(AnalysisParameters.ScriptsDir)
end %Function


