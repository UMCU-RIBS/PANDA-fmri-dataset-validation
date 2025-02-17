function val = json_to_struct(json)
    fid = fopen(json, 'r');
    raw = fread(fid, inf);
    str = char(raw');
    fclose(fid);
    val = jsondecode(str);
end