function fs_recon_all_loop(root, fs_folder)
% Map the anatomical images of all participants to FreeSurfer surface space
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
        for j = 1:numel(sessions)
            dtype_folder = strcat(subj_folder, '/', sessions{j}, '/anat');
            if ~isfolder(dtype_folder)
                continue
            end
            files = dir(dtype_folder);
            dir_flags = [files.isdir];
            files = {files(~dir_flags).name};
            files = files(contains(files, '.nii'));
            files = fullfile(dtype_folder, files);
            for k = 1:numel(files)            
                if contains(file, "mansfield")
                    settings = "-all -cw256";
                else
                    settings = "-all";
                end
                if isfolder(fullfile(fs_folder, subj))
                    subj = strcat(subj, '_2');
                end
                command = strcat("recon-all -i ", file, " -s ", subj, " -sd ", fs_folder, " ", settings);
                display(command)
                system(command)
            end
        end
    end
    fprintf('recon_all done!\n')
end