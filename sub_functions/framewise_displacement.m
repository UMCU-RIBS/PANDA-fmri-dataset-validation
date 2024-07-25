function fd = framewise_displacement(nifti)
% FRAMEWISE_DISPLACEMENT calculates the framewise displacement for each
% volume in a given NIfTI file.
%   @input: unprocessed NIfTI file for a given subject
%       A transformation matrix (.mat file) for this NIfTI file should be
%       present in the same folder as the NIfTI. The transformation matrix can be
%       acquired by realigning and coregistering the functional file to the
%       subject's anatomical T1 image.
%   @output: list of framewise displacement values for each frame in the
%   input file.

    fd = [];
    transformation_matrix = strrep(nifti, '.nii', '.mat');
    if ~isfile(transformation_matrix)
        disp(strcat('there is no transformation matrix for subject: ', extractBetween(transformation_matrix, 'func/sub-', '_ses')))
        return
    end
    trans_mat = load(transformation_matrix);
    nii = niftiread(nifti);

    % get first volume
    nii = nii(:,:,:,1);
    
    % get matrix coordinates of voxels inside of brain (over 100)
    [x,y,z] = ind2sub(size(nii), find(nii > 100));
    
    % subtract one from each to account for zero indexing
    x = x-1;
    y = y-1;
    z = z-1;
    
    % create matrix of 4 x number of voxels, fourth row is all ones, to allow
    % for matrix multiplication
    matrix = [x, y, z, ones(size(x,1), 1)];
    
    % initialize FD vector
    fd = zeros(size(trans_mat.mat,3), 1);
    
    % loop over the size of the third dimension of mat
    for j = 2:size(trans_mat.mat,3)
    
        % get the actual coordinates for each volume by multiplying the placement
        % of the brain by the transformation matrix of the frame in question
        previous_tmp = matrix * trans_mat.mat(:,:,j-1)';
        current_tmp = matrix * trans_mat.mat(:,:,j)';
    
        % subtract the previous volume from the current volume and get the Euclidean distances
        displacement = sqrt(sum((current_tmp(:, 1:3) - previous_tmp(:, 1:3)).^2, 2));
    
        % use Euclidean distances to compute framewise displacement
        fd(j) = mean(displacement);
    end
    if all(trans_mat.mat(:,:,1) == 0)
        fd(2) = mean(fd(3:end));
    end
end