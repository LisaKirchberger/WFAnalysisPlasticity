function convert2LogTable(LogPath)

load(LogPath)

Trial = Log.Trial(end);
Log_table = table;
Log_fieldnames = fieldnames(Log);
for f = 1:length(Log_fieldnames)
    FieldData = getfield(Log, char(Log_fieldnames(f))); %#ok<GFLD>
    if ischar(FieldData)
        FieldData = repmat(FieldData,Trial,1);
    elseif strcmp(char(Log_fieldnames(f)), 'LoadedFiles')
        FieldData = [FieldData.name];
        FieldData = repmat(FieldData,Trial,1);
    elseif length(FieldData) ~= Trial
        FieldData(length(FieldData)+1:Trial) = NaN;
        FieldData = FieldData';
    else
        FieldData = FieldData';
    end
    eval([ 'Log_table.' char(Log_fieldnames(f)), '=', 'FieldData', ';'])
end

if exist('RunningTimecourseAVG', 'var')
    save(LogPath, 'Log', 'Log_table', 'Par', 'RunningTimecourseAVG')
else
    save(LogPath, 'Log', 'Log_table', 'Par')
end
        

end

