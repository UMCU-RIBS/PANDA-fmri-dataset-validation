function reconcatenate_loop(root)
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
                display(['no func folder for ' subj, sessions{j}])
                continue
            end
            files = dir(dtype_folder);
            dir_flags = [files.isdir];
            files = {files(~dir_flags).name};
            files = files(contains(files, '.gii'));
            files = files(contains(files, 'rusub'));
            file_end = cellfun(@(str) str(end-3:end), files, 'UniformOutput', false);
            remove = cellfun(@(str) ~isempty(regexp(str, '\d{4}$', 'once')), file_end);
            files(remove) = [];
            files = fullfile(dtype_folder, files);
            files = files(contains(files, 'bold_lh.gii'));

            for k = 1:length(files)
                l_file = files{k};
                available_files = all_steps_file(l_file);
                if available_files.giftis_reconcatenated == 0 && available_files.gifti_created == 1
                    r_file = strrep(l_file, '_bold_lh', '_bold_rh');
                    surffile='fsaverage.inflated.surf.gii';
                    lh_dat=gifti(l_file);
                    rh_dat=gifti(r_file);
                    opfile=strrep(l_file,'_lh.gii','.gii');
                    for q=1:size(lh_dat.cdata,2)
                        gg = gifti([lh_dat.cdata(:,q);rh_dat.cdata(:,q)]);
                        gg.private.metadata(1).name='SurfaceID';
                        gg.private.metadata(1).value=surffile;
                        save(gg,spm_file(opfile,'suffix',sprintf('-%04d',q)),'ExternalFileBinary');
                    end
                end
            end
        end
    end
end