main_script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(main_script_dir, 'sub_functions'))
addpath(fullfile(main_script_dir, 'main_functions'))

root = ''; % add name of the root folder of the BIDS dataset

%% Compute framewise displacement
% This step requires each subject's functional scans to be realigned and
% coregistered to their anatomical T1 image.
FD_table = fd_table(root);

%% Compute motion outliers
% This step requires FMRIB Software Library
% (FSL, https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/) to be installed. Windows users
% are recommended to use Windows Subsystem for Linux (WSL) to run FSL.
FSL_motion_outliers_table = fsl_motion_outliers_table(root);