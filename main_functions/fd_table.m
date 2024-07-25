function FD_table = fd_table(root)
%FD_TABLE Computes framewise displacement for each subject in 'root' folder
%   @input:
%   root: name of the root folder of the BIDS dataset
%   @output:
%   FD_table: table specifying the subject number, session, task and run
%   number with the framewise displacement for each volume in the dataset.

    subj_list = dir(root);
    dir_flags = [subj_list.isdir];
    subj_list = {subj_list(dir_flags).name};
    subj_list = subj_list(~ismember(subj_list, {'.', '..','task_examples'}));
    fd_all = [];
    file_all = [];

    for i = 1:numel(subj_list)
        subj = subj_list{i};
        subj_folder = strcat(root, '/', subj);
        sessions = dir(subj_folder);
        dir_flags = [sessions.isdir];
        sessions = {sessions(dir_flags).name};
        sessions = sessions(~ismember(sessions, {'.', '..'}));
        for j = 1:numel(sessions)
            dtype_folder = strcat(subj_folder, '/', sessions{j}, '/func');
            if ~isfolder(dtype_folder)
                continue
            end
            files = dir(dtype_folder);
            dir_flags = [files.isdir];
            files = {files(~dir_flags).name};
            files = files(contains(files, '.nii') & startsWith(files, 'sub'));
            files = fullfile(dtype_folder, files);
            for k = 1:numel(files)
                file = fullfile(dtype_folder, files{k});
                fd = framewise_displacement(file);
                fd_all = [fd_all; fd];
                file_all = [file_all; repmat(convertCharsToStrings(extractAfter(files{k}, '/func/')), size(fd,1),1)];
            end
        end
    end

    % Create table
    subject = extractBetween(file_all, 'sub-', '_ses');
    session = extractBetween(file_all, 'ses-', '_task');
    task = extractBetween(file_all, 'task-', '_run');
    run = str2double(extractBetween(file_all, 'run-', '_'));

    FD_table = table();

    FD_table.Subject = subject;
    FD_table.Session = session;
    FD_table.Task = task;
    FD_table.Run = run;
    FD_table.Framewise_displacement = fd_all;
end

