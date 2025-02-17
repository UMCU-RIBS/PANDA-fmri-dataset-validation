function event_struct = tsv_to_struct(events)
    fid = fopen(events, 'r');
    raw = fread(fid, inf);
    str = char(raw');
    fclose(fid);
    lines = strsplit(str, '\n');
    non_empty_rows = ~cellfun('isempty', lines) & ~cellfun(@(x) isequal(x, char.empty), lines);
    lines = lines(non_empty_rows);
    event_struct(numel(lines)-1).onset = [];
    event_struct(numel(lines)-1).duration = [];
    event_struct(numel(lines)-1).trial_type = [];
    for i = 2:numel(lines)
        values = split(lines{i});
        event_struct(i-1).onset = str2double(values{1});
        event_struct(i-1).duration = str2double(values{2});
        event_struct(i-1).trial_type = values{3};
    end
end