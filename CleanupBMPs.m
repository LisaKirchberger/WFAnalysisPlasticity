%% Set Datapath to Folder of Mouse you would like to clean up

MouseName = 'Bran';

datapath = ['\\vc2nin\Mouse_Plasticity\RawData\', MouseName]; 
subdirs = dir(fullfile(datapath));
subdirs(~cell2mat(cellfun(@(X) isdir(fullfile(datapath,X)),{subdirs(:).name},'UniformOutput',0))) = [];
subdirs(cell2mat(cellfun(@(X) ismember(X,{'.','..', 'Thumbs.db'}),{subdirs(:).name},'UniformOutput',0))) = [];

for subidx =1:length(subdirs)
    paths = dir(fullfile(datapath,subdirs(subidx).name));
    paths(cell2mat(cellfun(@(X) ismember(X,{'.','..', 'Thumbs.db'}),{paths(:).name},'UniformOutput',0))) = [];
    paths = cellfun(@(X) fullfile(datapath,subdirs(subidx).name,X),{paths(:).name},'UniformOutput',0);
    
    %% Start general script
    for pid = 1:length(paths)
        
        curcd = fullfile(paths{pid});

        cd(curcd)
        folders = dir(curcd);
        folders(~cellfun(@isdir,{folders(:).name})) = [];
        folders(cell2mat(cellfun(@(X) ismember(X,{'.','..'}),{folders(:).name},'UniformOutput',0))) = [];
        for fid = 1:length(folders)
            cd(curcd)
            cd(folders(fid).name)
            
            listbmps = dir('*.bmp');
            listtiffs= dir('*.tiff');
            mark4removal = cellfun(@(X) X==641078 || X==5120000,{listbmps(:).bytes});

            if length(listbmps)==length(listtiffs) && any(mark4removal)
                disp(['Removing all raw data from folder for ' curcd ' ' folders(fid).name])
                cellfun(@delete,{listbmps(:).name})
            elseif length(listbmps)==length(listtiffs) && ~any(mark4removal)
                disp(['No raw data in folder for ' curcd ' ' folders(fid).name])
            elseif length(listtiffs)>length(listbmps)
                disp(['Raw data already removed for ' curcd ' ' folders(fid).name])
            elseif length(listbmps)>length(listtiffs)
                disp(['No preprocessed data for ' curcd ' ' folders(fid).name '; cannot remove raw data. Use downsampleraw first!'])
            end
            
        end
        
    end
end