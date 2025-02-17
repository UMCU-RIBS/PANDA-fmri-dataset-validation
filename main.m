main_script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(main_script_dir, 'sub_functions'))
addpath(fullfile(main_script_dir, 'main_functions'))
addpath('') % add path to FreeSurfer functions, including recon_all and vol2surf

%% Set variables
root = ''; % add path to raw data
fs_folder = ''; % add path to where the FreeSurfer surface images should be
taskname = ''; % specify task to filter the GLM. If all tasks, then this should be "all"

%% SPM preprocessing
% First step: perform SPM preprocessing until coregistration.
% Requires SPM to be installed and path to its functions
preprocessing_spm(root)

% After this step, both framewise displacement and FSL motion outliers can be computed.
%% Compute framewise displacement
FD_table = fd_table(root);

%% Compute motion outliers
% This step requires FMRIB Software Library
% (FSL, https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/) to be installed. Windows users
% are recommended to use Windows Subsystem for Linux (WSL) to run FSL.
FSL_motion_outliers_table = fsl_motion_outliers_table(root);

%% Transformation to surface data
% First step: perform FreeSurfer on all subjects.
% This step requires FreeSurfer to be installed.
fs_recon_all_loop(root, fs_folder)
    
% Second step: create giftis
create_giftis_loop(root, fs_folder)

% Third step: create and add fsaverage brain to all subject folders
create_fsaverage(fs_folder)
add_fsaverage(root, fs_folder)

% Fourth step: reconcatenate giftis
reconcatenate_loop(root)

%% First-level analysis
% If GLM fails for any participants, the error is caught and shown.
% Variable 'taskname' can be used to specify a certain task to analyse.
% If all tasks should be used, then taskname = "all"
failed_participants = surface_glm(root, taskname);