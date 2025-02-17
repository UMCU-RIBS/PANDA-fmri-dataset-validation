function available_files = all_steps_file(file)
    available_files = struct([]);
    file_folder = fileparts(file);
    files = dir(file_folder);
    dir_flags = [files.isdir];
    files = {files(~dir_flags).name};

    available_files(1).nifti_unwarped = 0;
    available_files(1).nifti_coregistered = 0;
    available_files(1).nifti_normalised = 0;
    available_files(1).nifti_smoothed = 0;
    available_files(1).gifti_created = 0;
    available_files(1).giftis_reconcatenated = 0;

    % find all non-json files
    files = files(~contains(files, '.json') & ...
                  ~contains(files, 'meanusub') & ...
                  ~contains(files, 'rp_sub') & ...
                  ~contains(files, 'register.dat') & ...
                  ~contains(files, '.mat'));

    file = unique(extractBetween(file, 'task-', '.'));

    if strcmp(file{1}(end-2:end), '_lh') || strcmp(file{1}(end-2:end), '_rh')
        file{1}(end-2:end) = [];
    end
    scan_associated = files(contains(files, file));
    

    [~, filename] = fileparts(scan_associated);
    if ~iscell(filename)
        filename = {filename};
    end
    filename = cellfun(@(str) str(end-3:end), filename, 'UniformOutput', false);
    if any(cellfun(@(filename) ~isempty(regexp(filename, '\d{4}$')), filename))
        available_files.giftis_reconcatenated = 1;
    end
    if any(contains(scan_associated, '.gii'))
        available_files.gifti_created = 1;
    end
    if any(contains(scan_associated, 'swusub'))
        available_files.nifti_smoothed = 1;
    end
    if any(contains(scan_associated, 'wusub'))
        available_files.nifti_normalised = 1;
    end
    if any(contains(scan_associated, 'rusub'))
        available_files.nifti_coregistered = 1;
    end
    if any(contains(scan_associated, 'usub'))
        available_files.nifti_unwarped = 1;
    end
end