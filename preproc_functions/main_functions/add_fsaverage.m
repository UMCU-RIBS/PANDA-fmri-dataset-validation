function add_fsaverage(root, fs_folder)
    subj_list = dir(root);
    dir_flags = [subj_list.isdir];
    subj_list = {subj_list(dir_flags).name};
    subj_list = subj_list(~ismember(subj_list, {'.', '..', 'task_examples'}));

    for i = 1:numel(subj_list)
        subj_folder = strcat(root, "/", subj_list{i});
        sessions = dir(subj_folder);
        dir_flags = [sessions.isdir];
        sessions = {sessions(dir_flags).name};
        sessions = sessions(~ismember(sessions, {'.', '..'}));
        for j = 1:size(sessions,2)
            dtype_folder = strcat(subj_folder, "/", sessions{j}, "/func");
            if isfolder(dtype_folder)
                files = dir(dtype_folder);
                dir_flags = [files.isdir];
                files = {files(~dir_flags).name};
                if ~contains(files, "fsaverage.inflated.surf.gii")
                    orig_file = fullfile(fs_folder, "fsaverage_gii/fsaverage.inflated.surf.gii");
                    new_file = fullfile(dtype_folder, "fsaverage.inflated.surf.gii");
                    copyfile(orig_file, new_file)
                end
            else
                disp(strcat('No folder found for subject:', subj_list{i}))
                continue
            end
        end
    end
end