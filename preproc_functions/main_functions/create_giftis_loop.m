function create_giftis_loop(root, fs_folder)
    subj_list = dir(root);
    dir_flags = [subj_list.isdir];
    subj_list = {subj_list(dir_flags).name};
    subj_list = subj_list(~ismember(subj_list, {'.', '..', 'task_examples'}));

    for i = 1:numel(subj_list)
        subj = subj_list{i};
        subj_folder = strcat(root, '/', subj);
        sessions = dir(subj_folder);
        dir_flags = [sessions.isdir];
        sessions = {sessions(dir_flags).name};
        sessions = sessions(~ismember(sessions, {'.', '..'}));
        for j = 1:length(sessions)
            dtype_folder = strcat(subj_folder, '/', sessions{j}, '/func');
            if ~isfolder(dtype_folder)
                continue
            end
            files = dir(dtype_folder);
            dir_flags = [files.isdir];
            files = {files(~dir_flags).name};
            files = files(contains(files, '.nii'));
            files = files(contains(files, 'rusub'));
            for k = 1:length(files)
                file = fullfile(dtype_folder, files{k});
                available_files = all_steps_file(file);
                if available_files.gifti_created == 0
                    fs = {dir(fs_folder).name};
                    fs = fs(contains(fs, subj));
                    if numel(fs) > 1
                        ses = strcat('ses', extractBetween(file, '_ses', '_task'));
                        if ~isempty(fs(contains(fs, ses)))
                            fs = fs(contains(fs, ses));
                        end
                        if numel(fs) > 1
                            fs = fs(1);
                        end
                    end
                    subj = fs;
                    if isempty(fs)
                        disp(strcat('no freesurfer folder for: ', file))
                        return
                    end
                    fs = fullfile(fs_folder, fs{1},'mri', 'orig.mgz');
                    if ~isfile(fs)
                        disp(strcat("orig file is missing for: ", subj))
                        return
                    end
                    setenv('SUBJECTS_DIR', fs_folder)
                    file_str = convertCharsToStrings(file);
                    subj_str = convertCharsToStrings(subj{1});
                    
                    % NB all inputs need to be strings, no character arrays.
                    vol2surf(file_str, subj_str, "--projfrac 0.5 --trgsubject fsaverage_sym --surf-fwhm 6.0", ".gii");
                end
            end
        end
    end
end