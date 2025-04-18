datdir=".../ds005366-dataset/";
funcdirs=unique(string({subdir(char(datdir+"rsub*bold.nii")).folder}))+"/";
andirs=replace(funcdirs,"func","anat");
nrdirs=numel(funcdirs);

for i = 1:nrdirs

    rfuncfiles=string({subdir(char(funcdirs(i)+"rsub*bold.nii")).name});
    snrfile=strrep(rfuncfiles,".nii","_snr.nii");
    nrfunc=numel(rfuncfiles);

    for j = 1:nrfunc
        funcdat = niftiread(rfuncfiles(j));
        hdr.    = niftiinfo(rfuncfiles(j));
        nrvol.  = hdr.ImageSize(4);
        nrfilt. = round((hdr.PixelDimensions(4)*nrvol)/100);
        fmatrix = make_filter(nrfilt,nrvol);

        [~,~,funcdat] = fmri_multiregress_vol(single(funcdat),fmatrix,ones(size(funcdat,[1,2,3])));
        snr           = mean(single(funcdat),4)./std(single(funcdat),0,4);
        
	hdr.ImageSize             = hdr.ImageSize(1:3);
        hdr.PixelDimensions       = hdr.PixelDimensions(1:3);
        hdr.Datatype              = 'single';
        hdr.MultiplicativeScaling = 1.0;
        niftiwrite(snr,snrfile(j),hdr);
    end

    if isdir(andirs(i))
        anfile.     = {[subdir(char(andirs(i)+"y_*T1w.nii")).name]};
        aninput.    = {char(anfile+",1")};
        ipsnrfiles  = cellstr(snrfile+",1")';
        clear matlabbatch;

        matlabbatch{1}.spm.spatial.normalise.write.subj.def        = anfile;
        matlabbatch{1}.spm.spatial.normalise.write.subj.resample   = ipsnrfiles;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb     = [-78 -112 -70
                                                                  78 76 85];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox    = [2 2 2];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
        spm_jobman('run',matlabbatch);
        clear matlabbatch;
    end

end

