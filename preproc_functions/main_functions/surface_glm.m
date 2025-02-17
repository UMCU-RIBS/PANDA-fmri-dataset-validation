function failed_participants = surface_glm(root, taskname)
    failed_participants = {};
    subj_list = dir(root);
    dir_flags = [subj_list.isdir];
    subj_list = {subj_list(dir_flags).name};
    subj_list = subj_list(~ismember(subj_list, {'.', '..', 'task_examples'}));

    for i = 1:numel(subj_list)
        subj = subj_list{i,1};
        % save subject folder
        subj_folder = fullfile(root, subj);
        % get all folders in subject folder
        sessions = dir(subj_folder);
        % no nifti files stored at this level, so only look at folders
        dir_flags = [sessions.isdir];
        sessions = {sessions(dir_flags).name};
        sessions = sessions{~ismember(sessions, {'.', '..'})};

        % loop through sessions
        for j = 1:numel(sessions)
            % define session path
            if numel(sessions) < 1
                ses_folder = fullfile(subj_folder, sessions{j});
            else
                ses_folder = fullfile(subj_folder, sessions);
            end
            % get folders in session
            % define path
            dtype_folder = fullfile(ses_folder, 'func');
            % get files in folder
            files = dir(dtype_folder);
            % exclude potential sub folders (including hidden folders)
            dir_flags = [files.isdir];
            files = {files(~dir_flags).name};
            [~, filename, orig_ext] = fileparts(files);
            % check whether functional scans are available, continue if not
            if (isempty(files) && j == numel(sessions))
                fprintf('no func folder for %s \n', subj_list{i})
                break
            elseif isempty(files)
                fprintf('no func folder for %s \n', subj_list{i})
                continue
            end
            original_files{1} = strcat(filename(startsWith(filename, "sub")), orig_ext(startsWith(filename, "sub")));
            original_files{1} = original_files{1}(endsWith(original_files{1}, ".nii"));

            % check whether the runs match task of interest
            if ~strcmpi(taskname, "all")
                original_files{1} = original_files{1}(contains(original_files{1}, taskname));
            end
            % continue with next participant if no tasks of interest
            if isempty(original_files{1})
                break
            end

            rt{1} = zeros(1,size(original_files{1}, 2));
            task{1} = strings(1,size(original_files{1}, 2));
            giftis{1} = cell(1,size(original_files{1}, 2));
            % loop through original files
            m = 1;
            for k = 1:numel(original_files{1})
                % get repetition time (+ any other info needed from json sidecar)
                tmp_json = fullfile(dtype_folder, strrep(original_files{1}{k}, '.nii', '.json'));
                val = json_to_struct(tmp_json);
                rt{1}(k) = val.RepetitionTime;
                task{1}(k) = val.TaskName;               
                giftis{1}{m} = files(~contains(files, {'h.gii', 'fsaverage.inflated.surf.gii'}));
                giftis{1}{m} = giftis{1}{m}(contains(giftis{1}{m}, '.gii'));
                giftis{1}{m} = giftis{1}{m}(contains(giftis{1}{m}, extractBefore(original_files{1}{k}, '.nii')));

                %Debugger; not enough surface files found
                if ismember('NDynamics', fieldnames(val))
                    dynamics_nr = val.NDynamics;
                elseif ismember('n_dynamics', fieldnames(val))
                    dynamics_nr = val.n_dynamics;
                end
                %if val.NDynamics*0.8 > size(giftis{1}{m},2) %changed JSON name for n_dynamics
                if dynamics_nr*0.8 > size(giftis{1}{m},2)
                    giftis{1}(m) = [];
                    disp(strcat("the following file has less than 80% of the expected amount of volumes and will not be included in the analysis: ", original_files{1}{m}))
                    continue
                end
                m = m + 1;
            end
            if ~isempty(giftis{1})
                if ~all(mean(rt{1}) == rt{1})
                    unique_rt = unique(rt{1});
                    tmp_original_files = original_files{1};
                    tmp_giftis = giftis{1};
                    tmp_rt = rt{1};
                    tmp_task = task{1};
                    original_files = cell(1,numel(unique_rt));
                    giftis = cell(1,numel(unique_rt));
                    rt = cell(1,numel(unique_rt));
                    task = cell(1,numel(unique_rt));
                    for a=1:numel(unique_rt)
                        original_files{a} = tmp_original_files(tmp_rt==unique_rt(a));
                        giftis{a} = tmp_giftis(tmp_rt==unique_rt(a));
                        rt{a} = tmp_rt(tmp_rt==unique_rt(a));
                        task{a} = tmp_task(tmp_rt==unique_rt(a));
                    end
                end
                for a = 1:numel(giftis)
                    try
                        % reset matlab batch
                        matlabbatch = struct([]);
                        giftis{a} = cellfun(@(x) strcat(dtype_folder, '/', x), giftis{a}, 'UniformOutput', false);
                        
                        directory = {extractBefore(strrep(giftis{a}{1}{1}, 'func', 'spm_stats'), "rusub")};
                        if isfolder(directory{1})
                            directory = strrep(directory, 'spm_stats', 'spm_stats_2');
                        end
                        %everything seems to be ok until here
                        matlabbatch{1}.spm.stats.fmri_spec.dir = directory;
                        matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
                        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = rt{a}(1);
                        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
                        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
                        for k = 1:length(giftis{a})
                            matlabbatch{1}.spm.stats.fmri_spec.sess(k).scans = giftis{a}{k}';
                            events = fullfile(dtype_folder, strrep(original_files{a}{k}, "_bold.nii", "_events.tsv"));
                            events = tsv_to_struct(events);
                            if (task{a}(k) == "Mapping3Fingers")
                                thumb_idx = contains({events.trial_type}, "thumb");
                                thumb_onset = [events(thumb_idx).onset];
                                thumb_duration = [events(thumb_idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).name = 'boldfinger: thumb';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).onset = thumb_onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).duration = thumb_duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).orth = 1;
        
                                index_idx = contains({events.trial_type}, "index");
                                index_onset = [events(index_idx).onset];
                                index_duration = [events(index_idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).name = 'boldfinger: index';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).onset = index_onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).duration = index_duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).orth = 1;
    
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).regress = struct('name', {}, 'val', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi_reg = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).hpf = 128;
    
                            elseif all(task{a}(k) == "Motor2Class") || all(task{a}(k) == "Sensory2Class")
                                move_idx = contains({events.trial_type}, "move");
                                onset = [events(move_idx).onset];
                                duration = [events(move_idx).duration];
                                if all(task{a}(k) == "Motor2Class")
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.name = 'Motor2Class: move';
                                elseif all(task{a}(k) == "Sensory2Class")
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.name = 'Sensory2Class: feel';
                                end
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.orth = 1;
    
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).regress = struct('name', {}, 'val', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi_reg = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).hpf = 128;
                        
                            elseif all(task{a}(k) == "Motor2ClassKids")
                                move_idx = contains({events.trial_type}, "move");
                                onset = [events(move_idx).onset];
                                duration = [events(move_idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.name = 'Motor2Class-kids: move';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond.orth = 1;
    
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).regress = struct('name', {}, 'val', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi_reg = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).hpf = 128;
    
                            elseif (task{a}(k) == "Mapping5Fingers")
                                idx = contains({events.trial_type}, "index_close");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).name = 'index close';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).orth = 1;
        
                                idx = contains({events.trial_type}, "index_open");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).name = 'index open';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).orth = 1;
        
                                idx = contains({events.trial_type}, "little_close");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(3).name = 'little close';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(3).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(3).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(3).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(3).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(3).orth = 1;
    
                                idx = contains({events.trial_type}, "little_open");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(4).name = 'little open';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(4).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(4).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(4).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(4).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(4).orth = 1;
        
                                idx = contains({events.trial_type}, "middle_close");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(5).name = 'middle close';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(5).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(5).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(5).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(5).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(5).orth = 1;
        
                                idx = contains({events.trial_type}, "middle_open");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(6).name = 'middle open';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(6).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(6).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(6).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(6).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(6).orth = 1;
        
                                idx = contains({events.trial_type}, "ring_close");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(7).name = 'ring close';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(7).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(7).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(7).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(7).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(7).orth = 1;
        
                                idx = contains({events.trial_type}, "ring_open");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(8).name = 'ring open';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(8).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(8).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(8).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(8).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(8).orth = 1;
        
                                idx = contains({events.trial_type}, "thumb_close");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(9).name = 'thumb_close';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(9).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(9).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(9).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(9).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(9).orth = 1;
    
                                idx = contains({events.trial_type}, "thumb_open");
                                onset = [events(idx).onset];
                                duration = [events(idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(10).name = 'thumb_open';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(10).onset = onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(10).duration = duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(10).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(10).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(10).orth = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).regress = struct('name', {}, 'val', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi_reg = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).hpf = 128;
        
                            elseif (task{a}(k) == "Motor3Class")
                                move_idx = contains({events.trial_type}, "move");
                                move_onset = [events(move_idx).onset];
                                move_duration = [events(move_idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).name = 'murge: move';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).onset = move_onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).duration = move_duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(1).orth = 1;
    
                                imagine_idx = contains({events.trial_type}, "imagine");
                                imagine_onset = [events(imagine_idx).onset];
                                imagine_duration = [events(imagine_idx).duration];
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).name = 'murge: imagine';
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).onset = imagine_onset;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).duration = imagine_duration;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).tmod = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).cond(2).orth = 1;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).regress = struct('name', {}, 'val', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).multi_reg = {''};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(k).hpf = 128;
                            end
                        end
                        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
                        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
                        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
                        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
                        matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.1;
                        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
                        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
                        matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
                        matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
                        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
            
                        matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
                        
                        task_length = zeros(1,numel(task{a}));
                        for p=1:numel(task{a})
                            if task{a}(p) == "Motor2Class" || task{a}(p) == "Sensory2Class"
                                task_length(p) = 2;
                            elseif task{a}(p) == "Motor2Class-kids"
                                task_length(p) = 2;
                            elseif task{a}(p) == "Motor3Class"
                                task_length(p) = 3;
                            elseif task{a}(p) == "Mapping3Fingers"
                                task_length(p) = 3;
                            elseif task{a}(p) == "Mapping5Fingers"
                                task_length(p) = 11;
                            end
                        end
                        weights_length = sum(task_length);
                        zero_weights = zeros(1,weights_length);
                        x=1;
                        cons = [];
                        name = [];
                        for p = 1:numel(task{a})
                            starting_point = 1;
                            if p-1 > 0
                                starting_point = sum(task_length(1:p-1))+1;
                            end
                            con_idx = starting_point:starting_point+task_length(p)-1;
                            if strcmpi(task{a}{p}, "Motor2Class")
                                cons{1} = [1 -1];
                                name{1} = 'Motor2Class: move';
                            elseif strcmpi(task{a}{p}, "Sensory2Class")
                                cons{1} = [1 -1];
                                name{1} = 'Sensory2Class: feel';
                            elseif strcmpi(task{a}{p}, "Motor2Class-kids")
                                cons{1} = [1 -1];
                                name{1} = 'Motor2ClassKids: move';
                            elseif strcmpi(task{a}{p}, "Motor3Class")
                                cons{1} = [1 0 -1];
                                name{1} = 'Motor3Class: move';
                            elseif strcmpi(task{a}{p}, "Mapping3Fingers")
                                cons{1} = [2 -1 -1];
                                name{1} = 'Mapping3Fingers: thumb';
                                cons{2} = [-1 2 -1];
                                name{2} = 'Mapping3Fingers: index';
                                cons{3} = [-1 -1 2];
                                name{3} = 'Mapping3Fingers: pinky';
                            elseif strcmpi(task{a}{p}, "Mapping5Fingers")
                                cons{1} = [4 4 -1 -1 -1 -1 -1 -1 -1 -1 0];
                                name{1} = 'Mapping5Fingers: index';
                                cons{2} = [-1 -1 4 4 -1 -1 -1 -1 -1 -1 0];
                                name{2} = 'Mapping5Fingers: little';
                                cons{3} = [-1 -1 -1 -1 4 4 -1 -1 -1 -1 0];
                                name{3} = 'Mapping5Fingers: middle';
                                cons{4} = [-1 -1 -1 -1 -1 -1 4 4 -1 -1 0];
                                name{4} = 'Mapping5Fingers: ring';
                                cons{5} = [-1 -1 -1 -1 -1 -1 -1 -1 4 4 0];
                                name{5} = 'Mapping5Fingers: thumb';
                                cons{6} = [1 1 1 1 1 1 1 1 1 1 -10];
                                name{6} = 'Mapping5Fingers: all fingers vs rest';
                            end
                            for w = 1:numel(cons)
                                weights = zero_weights;
                                weights(con_idx) = cons{w};
                                matlabbatch{3}.spm.stats.con.consess{x}.tcon.name = name{w};
                                matlabbatch{3}.spm.stats.con.consess{x}.tcon.weights = weights;
                                matlabbatch{3}.spm.stats.con.consess{x}.tcon.sessrep = 'none';
                                matlabbatch{3}.spm.stats.con.delete = 0;
                                x=x+1;
                            end
                        end
                        if isfolder(matlabbatch{1}.spm.stats.fmri_spec.dir{1})
                            stats = dir(matlabbatch{1}.spm.stats.fmri_spec.dir{1});
                            dir_flags = [stats.isdir];
                            stats = {stats(~dir_flags).name};
                            for m = 1:numel(stats)
                                delete(fullfile(matlabbatch{1}.spm.stats.fmri_spec.dir{1}, stats{m}))
                            end
                            rmdir(matlabbatch{1}.spm.stats.fmri_spec.dir{1})
                        end
                        spm_jobman('run', matlabbatch)
                    catch ME
                        % If an error occurs, store the participant and the error message
                        warning('GLM failed for %s: %s', subj, ME.message);
                        failed_participants{end+1} = struct('participant', subj, 'error', ME.message);
                    end
                end
            end
        end
    end
end