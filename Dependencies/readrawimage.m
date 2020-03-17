function image = readrawimage(path)

try
    fid = fopen(path, 'r');
    a = uint16(fread(fid, inf, 'int16'));
    a = reshape(a, sqrt(size(a, 1)), sqrt(size(a, 1)));
    image=a';
    fclose(fid);
catch
    fclose(fid);
    return
end


end