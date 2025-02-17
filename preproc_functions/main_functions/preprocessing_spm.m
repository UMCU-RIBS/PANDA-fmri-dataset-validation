% For each file in each subfolder of each subject, run the preprocessing
% steps up to and including coregistration on the original, extracted file
% This is all done within a loop, ending in spm_jobman
function preprocessing_spm(root)
    % collect files per subject per session
    subj_list = dir(root);
    dir_flags = [subj_list.isdir];
    subj_list = {subj_list(dir_flags).name};
    subj_list = subj_list(~ismember(subj_list, {'.', '..', 'task_examples'}));

    for i = 1:numel(subj_list)
        subj = subj_list{i};
    
        % save subject folder
        subj_folder = fullfile(root, subj);
        % get all folders in subject folder
        sessions = dir(subj_folder);
        % no nifti files stored at this level, so only look at folders
        dir_flags = [sessions.isdir];
        sessions = {sessions(dir_flags).name};
        % exclude hidden files
        sessions = sessions(~ismember(sessions, {'.', '..'}));

        % loop through sessions
        for j = 1:length(sessions)
            ses_nifti_info = struct([]);
            ses_nifti_info(1).functional = {};
            ses_nifti_info(1).no_of_frames = {};
            ses_nifti_info(1).repetition_time = {};
            ses_nifti_info(1).task = {};
            ses_nifti_info(1).anatomical = '';
            % define session path
            ses_folder = fullfile(subj_folder, sessions{j});
            % get folders in session
            % define path
            dtype_folder = fullfile(ses_folder, 'func');
            if ~isfolder(dtype_folder)
                continue
            end
            % get files in folder
            files = dir(dtype_folder);
            % exclude potential sub folders (including hidden folders)
            dir_flags = [files.isdir];
            files = {files(~dir_flags).name};
            files = files(contains(files, '.nii'));
            files = files(startsWith(files, 'sub'));
            
            % loop through files
            for w = 1:length(files)
                % append path to file
                file = fullfile(dtype_folder, files{w});
    
                % get folder, name and extension of file
                [~, ~, extension] = fileparts(file);
                % check extension, if .gz, unzip
                if (strcmp(extension, '.gz'))
                    disp('BIDS structure contains zipped files')
                end
                available_files = all_steps_file(file);
                % get information from sidecar file
                sidecar = strrep(file, '.nii', '.json');
                sidecar = erase(sidecar, extractBetween(sidecar, '_bold', '.json'));
                val = json_to_struct(sidecar);
                if available_files.nifti_unwarped == 0
                    ses_nifti_info.functional{length(ses_nifti_info(1).functional)+1} = file;
                    ses_nifti_info.preprocessing_step(length(ses_nifti_info(1).functional)) = 0;
                elseif available_files.nifti_unwarped == 1
                    ses_nifti_info.functional{length(ses_nifti_info(1).functional)+1} = strrep(file, 'func/', 'func/u');
                    ses_nifti_info.preprocessing_step(length(ses_nifti_info(1).functional)) = 1;
                end
                ses_nifti_info.no_of_frames{length(ses_nifti_info(1).functional)} = val.NDynamics;
                ses_nifti_info.task(length(ses_nifti_info(1).functional)) = extractBetween(file, 'task-', '_run');
            end
            % if there are no functional files, continue to next session
            if isempty(ses_nifti_info.functional)
                continue
            end
            % get anatomical image
            anat_folder = fullfile(ses_folder, 'anat');
            anat_file = {dir(anat_folder).name};
            anat_file = anat_file(contains(anat_file, '.nii'));
            if numel(anat_file) > 1
                anat_file = anat_file(contains(anat_file, sessions{j}));
                if numel(anat_file) > 1
                    anat_file = anat_file(1);
                end
            end

            ses_nifti_info(1).anatomical = fullfile(anat_folder, anat_file);
            % check that anatomical image exists
            if ~isfile(ses_nifti_info.anatomical)
                disp(strcat("no freesurfer anatomical image for subject: ", subj))
                continue
            end
            %% perform SPM preprocessing
            ses_nifti_info(1).repetition_time = val.RepetitionTime;
            matlabbatch = struct([]);
            no_of_sessions = size(find(ses_nifti_info.preprocessing_step == 0),2);
            a = 1;
            if no_of_sessions > 0
                for m = find(ses_nifti_info.preprocessing_step == 0)
                    matlabbatch{a}.spm.util.exp_frames.files = ses_nifti_info.functional(m);
                    matlabbatch{a}.spm.util.exp_frames.frames = 1:ses_nifti_info.no_of_frames{m};
                    matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.data(a).scans(1) = cfg_dep('Expand image frames: Expanded filename list.', substruct('.','val', '{}',{a}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
                    matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.data(a).pmscan = '';
                    a = a + 1;
                end
                % fill in details
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.eoptions.sep = 4;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.eoptions.rtm = 0;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.eoptions.einterp = 2;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.eoptions.weight = '';
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.jm = 0;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.sot = [];
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uwroptions.mask = 1;
                matlabbatch{no_of_sessions + 1}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';
                spm_jobman('run', matlabbatch)
                % update files to new preprocessing step
                for m = find(ses_nifti_info.preprocessing_step == 0)
                    ses_nifti_info.functional(m) = strrep(ses_nifti_info.functional(m), 'func/', 'func/u');
                    ses_nifti_info.preprocessing_step(m) = 1;
                end
            end

            % coregister
            matlabbatch = struct([]);
            no_of_sessions = size(find(ses_nifti_info.preprocessing_step == 1), 2);
            if no_of_sessions > 0
                meanusub = {dir(dtype_folder).name};
                meanusub = meanusub(contains(meanusub, 'meanusub'));
                meanusub = fullfile(dtype_folder, meanusub{1});
                a=1;
                for m = find(ses_nifti_info.preprocessing_step == 1)
                    matlabbatch{a}.spm.util.exp_frames.files = ses_nifti_info.functional(m);
                    matlabbatch{a}.spm.util.exp_frames.frames = 1:ses_nifti_info.no_of_frames{m};
                    matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.other(a) = cfg_dep('Expand image frames: Expanded filename list.', substruct('.','val', '{}',{a}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
                    a = a+1;
                end
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.ref = ses_nifti_info.anatomical;
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.source(1) = {strcat(meanusub, ',1')};
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
                matlabbatch{no_of_sessions + 1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
                spm_jobman('run', matlabbatch);
            end
        end
    end
end

