function JSONdata = readJSONfile(path)

fid = fopen(path);
raw = fread(fid,inf);
str = char(raw');
fclose(fid);
JSONdata = jsondecode(str);

end