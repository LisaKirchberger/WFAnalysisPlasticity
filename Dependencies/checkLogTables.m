function [TrialLUT,Log_table] = checkLogTables(TrialLUT,Log_table)


if any(strcmp('Exposure', Log_table.Properties.VariableNames))
    if isa(Log_table.Exposure, 'char')
        Log_table.Exposure = table2array(varfun(@str2num, Log_table, 'InputVariables', 'Exposure'));
    end
end

% Need to do make the columns with chars into cells, otherwise can't concatenate tables if they don't fit together
FieldNames = Log_table.Properties.VariableNames;
for f = 1:length(FieldNames)
    FieldName = FieldNames{f};
    if isa(eval(['Log_table.' FieldName]), 'char')
        eval(['Log_table.' FieldName ' = cellstr(Log_table.' FieldName ');']) 
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
    
    % create the fields in the TrialLUT and fill with NaNs or empty cells
    EmptyColumn = NaN(size(TrialLUT,1),1); %#ok<NASGU>
    EmptyColumnCell = cell(size(TrialLUT,1),1); %#ok<*PREALL>
    for f = 1:size(missing_fields,2)
        FieldName = missing_fields{f};
        if isa(eval(['Log_table.' FieldName]), 'double')
            eval(['TrialLUT.', FieldName, ' = EmptyColumn;'])
        elseif isa(eval(['Log_table.' FieldName]), 'cell')
            eval(['TrialLUT.', FieldName, ' = EmptyColumnCell;'])
        else
            keyboard
        end
    end
    % sort the table columns
    TrialLUT = TrialLUT(:,sort(TrialLUT.Properties.VariableNames));
    
    % create the fields in the Log_table and fill with NaNs or empty cells
    EmptyColumn = NaN(size(Log_table,1),1);
    EmptyColumnCell = cell(size(Log_table,1),1);
    for f = 1:size(missing_fields2,2)
        FieldName = missing_fields2{f};
        if isa(eval(['TrialLUT.' FieldName]), 'double')
            eval(['Log_table.', FieldName, ' = EmptyColumn;'])
        elseif isa(eval(['TrialLUT.' FieldName]), 'cell')
            eval(['Log_table.', FieldName, ' = EmptyColumnCell;'])
        else
            keyboard
        end
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
    
    % create the fields in the TrialLUT and fill with NaNs or empty cells
    EmptyColumn = NaN(size(TrialLUT,1),1); %#ok<NASGU>
    EmptyColumnCell = cell(size(TrialLUT,1),1); %#ok<*PREALL>
    for f = 1:size(missing_fields,2)
        FieldName = missing_fields{f};
        if isa(eval(['Log_table.' FieldName]), 'double')
            eval(['TrialLUT.', FieldName, ' = EmptyColumn;'])
        elseif isa(eval(['Log_table.' FieldName]), 'cell')
            eval(['TrialLUT.', FieldName, ' = EmptyColumnCell;'])
        else
            keyboard
        end
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
    
    % create the fields in the Log_table and fill with NaNs or empty cells
    EmptyColumn = NaN(size(Log_table,1),1);
    EmptyColumnCell = cell(size(Log_table,1),1);
    for f = 1:size(missing_fields2,2)
        FieldName = missing_fields2{f};
        if isa(eval(['TrialLUT.' FieldName]), 'double')
            eval(['Log_table.', FieldName, ' = EmptyColumn;'])
        elseif isa(eval(['TrialLUT.' FieldName]), 'cell')
            eval(['Log_table.', FieldName, ' = EmptyColumnCell;'])
        else
            keyboard
        end
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
