function [TrialLUT,Log_table] = checkLogTables(TrialLUT,Log_table)

% Need to do make some fields into cells, otherwise can't concatenate the tables
if any(strcmp('Mouse', Log_table.Properties.VariableNames))
    if isa(Log_table.Mouse,'char')
        Log_table.Mouse = cellstr(Log_table.Mouse);
    end
end
if any(strcmp('Logfile_name', Log_table.Properties.VariableNames))
    if isa(Log_table.Logfile_name,'char')
        Log_table.Logfile_name = cellstr(Log_table.Logfile_name);
    end
end
if any(strcmp('Setup', Log_table.Properties.VariableNames))
    if isa(Log_table.Setup, 'char')
        Log_table.Setup = cellstr(Log_table.Setup);
    end
end
if any(strcmp('Laserpower', Log_table.Properties.VariableNames))
    if isa(Log_table.Laserpower, 'char')
        Log_table.Laserpower = cellstr(Log_table.Laserpower);
    end
end
if any(strcmp('Exposure', Log_table.Properties.VariableNames))
    if isa(Log_table.Exposure, 'char')
        Log_table.Exposure = table2array(varfun(@str2num, Log_table, 'InputVariables', 'Exposure'));
    end
end

% Sort the table columns
Log_table = Log_table(:,sort(Log_table.Properties.VariableNames));
TrialLUT = TrialLUT(:,sort(TrialLUT.Properties.VariableNames));

% find the missing fields
cmpTables = cellfun(@(c)strcmp(c,Log_table.Properties.VariableNames),TrialLUT.Properties.VariableNames, 'UniformOutput', false);
missing_fields = Log_table.Properties.VariableNames(~sum(vertcat(cmpTables{:}),1));
cmpTables2 = cellfun(@(c)strcmp(c,TrialLUT.Properties.VariableNames),Log_table.Properties.VariableNames, 'UniformOutput', false);
missing_fields2 = TrialLUT.Properties.VariableNames(~sum(vertcat(cmpTables2{:}),1));

% Fill missing fields with NaNs

if ~isempty(missing_fields) && ~isempty(missing_fields2) %fields missing in TrialLUT and Log_table
    
    % create the fields in the TrialLUT and fill with NaNs
    EmptyColumn = NaN(size(TrialLUT,1),1); %#ok<NASGU>
    for f = 1:size(missing_fields,2)
        FieldName = missing_fields{f};
        eval(['TrialLUT.', FieldName, ' = EmptyColumn;'])
    end
    % sort the table columns
    TrialLUT = TrialLUT(:,sort(TrialLUT.Properties.VariableNames));
    
    % create the fields in the Log_table and fill with NaNs
    EmptyColumn = NaN(size(Log_table,1),1);
    for f = 1:size(missing_fields2,2)
        FieldName = missing_fields2{f};
        eval(['Log_table.', FieldName, ' = EmptyColumn;'])
    end
    % sort the table columns
    Log_table = Log_table(:,sort(Log_table.Properties.VariableNames));
    
    
    % double check if you could combine the tables now
    try
        test = [TrialLUT; Log_table];
    catch
        keyboard
    end
    
    
elseif ~isempty(missing_fields) %fields missing in TrialLUT
    
    % create the fields in the combined table and fill with NaNs
    EmptyColumn = NaN(size(TrialLUT,1),1);
    for f = 1:size(missing_fields,2)
        FieldName = missing_fields{f};
        eval(['TrialLUT.', FieldName, ' = EmptyColumn;'])
    end
    % sort the table columns
    TrialLUT = TrialLUT(:,sort(TrialLUT.Properties.VariableNames));
    
    % double check if you could combine the tables now
    try
        test = [TrialLUT; Log_table];
    catch
        keyboard
    end
    
elseif ~isempty(missing_fields2) %fields missing in Log_table
    
    % create the fields in the combined table and fill with NaNs
    EmptyColumn = NaN(size(Log_table,1),1);
    for f = 1:size(missing_fields2,2)
        FieldName = missing_fields2{f};
        eval(['Log_table.', FieldName, ' = EmptyColumn;'])
    end
    % sort the table columns
    Log_table = Log_table(:,sort(Log_table.Properties.VariableNames));
    
    % double check if you could combine the tables now
    try
        test = [TrialLUT; Log_table];
    catch
        keyboard
    end
    
else
    
    % double check if you could combine the tables now
    try
        test = [TrialLUT; Log_table];
    catch
        keyboard
    end
end


end
