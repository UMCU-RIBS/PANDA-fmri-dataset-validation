function FSL_motion_outliers_table = fsl_motion_outliers_table(root)
% FSL_MOTION_OUTLIERS_TABLE: Computes motion outlier frames for each subject in 'root' folder
% This function calls the 'fsl_motion_outliers' function from FSL. Windows
% users may need slight adjustments, as specified in the code below.
%   @input:
%   root: name of the root folder of the BIDS dataset
%   @output:
%   Motion_table: table specifying the subject number, session, task and run
%   number with the number of frames, the number of motion outliers and percentage
%   of frames categorised as motion outliers for every scan.

% Compute motion outliers for each subject
    subj_list = dir(root);
    dir_flags = [subj_list.isdir];
    subj_list = {subj_list(dir_flags).name};
    subj_list = subj_list(~ismember(subj_list, {'.', '..', 'task_examples'}));
    frames = [];
    outliers = [];
    file_vector = [];

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
            files = files(contains(files, '.nii') & startsWith(files, 'sub'));
            for k = 1:numel(files)
                input_fname = fullfile(dtype_folder, files{k});
                output_fname = strrep(input_fname, '/func', '/fsl_motion_outliers');
                if ~isfolder(fileparts(output_fname))
                    mkdir(fileparts(output_fname))
                end
                
                % The command below calls FSL on Linux and macOS systems
                command = strcat("fsl_motion_outliers -i ", input_fname, " -o ", output_fname);
                
                % Uncomment the line below if using Windows Subsystem for
                % Linux (WSL) to run the FSL software.
                %command = strcat("wsl fsl_motion_outliers -i ", input_fname, " -o ", output_fname);

                system(command)

                outliers_fname = extractBefore(files{k}, '.nii');
                outliers_full_file = extractBefore(output_fname, '.nii');
                
                fmo = load(outliers_full_file, '-ascii');
                [frames(end+1), outliers(end+1)] = size(fmo);
                file_vector = [file_vector, convertCharsToStrings(outliers_fname)];
            end
        end
    end
    
    % Create table
    subj = extractBetween(file_vector, 'sub-', '_ses');
    sess = extractBetween(file_vector, 'ses-', '_task');
    task = extractBetween(file_vector, 'task-', '_run');
    run = str2double(extractBetween(file_vector, 'run-', '_'));

    FSL_motion_outliers_table = table();

    FSL_motion_outliers_table.Subject = subj';
    FSL_motion_outliers_table.Session = sess';
    FSL_motion_outliers_table.Task = task';
    FSL_motion_outliers_table.Run = run';
    FSL_motion_outliers_table.NoOfFrames = frames';
    FSL_motion_outliers_table.NoOfOutliers = outliers';
    FSL_motion_outliers_table.OutliersPercentage = outliers' ./ frames' * 100;
end