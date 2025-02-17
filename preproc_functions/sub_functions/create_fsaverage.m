function create_fsaverage(fs_folder)
    inflated_avg=strcat(fs_folder, '/fsaverage_gii/fsaverage.inflated.surf.gii');
    if ~isfile(inflated_avg)
        lfile=strcat(fs_folder, '/fsaverage_gii/lh.inflated.surf.gii');
        rfile=strcat(fs_folder, '/fsaverage_gii/rh.inflated.surf.gii');
        linflated=gifti(lfile);
        rinflated=gifti(rfile);
        linflated.vertices(:,1)=linflated.vertices(:,1)-max(linflated.vertices(:,1));
        rinflated.vertices(:,1)=rinflated.vertices(:,1)-min(rinflated.vertices(:,1));
        inflated=linflated;
        inflated.vertices=[linflated.vertices;rinflated.vertices];
        inflated.faces=[linflated.faces;rinflated.faces+numel(linflated.vertices)/3];
        save(inflated,inflated_avg);
    end
    
    pial_avg=strcat(fs_folder, '/fsaverage_gii/fsaverage.pial.surf.gii');
    if ~isfile(pial_avg)
        lfile=strcat(fs_folder, '/fsaverage_gii/lh.pial.surf.gii');
        rfile=strcat(fs_folder, '/fsaverage_gii/rh.pial.surf.gii');
        linflated=gifti(lfile);
        rinflated=gifti(rfile);
        inflated=linflated;
        inflated.vertices=[linflated.vertices;rinflated.vertices];
        inflated.faces=[linflated.faces;rinflated.faces+numel(linflated.vertices)/3];
        save(inflated,pial_avg);
    end
    
    white_avg=strcat(fs_folder, '/fsaverage_gii/fsaverage.white.surf.gii');
    if ~isfile(white_avg)
        lfile=strcat(fs_folder, '/fsaverage_gii/lh.white.surf.gii');
        rfile=strcat(fs_folder, '/fsaverage_gii/rh.white.surf.gii');
        linflated=gifti(lfile);
        rinflated=gifti(rfile);
        inflated=linflated;
        inflated.vertices=[linflated.vertices;rinflated.vertices];
        inflated.faces=[linflated.faces;rinflated.faces+numel(linflated.vertices)/3];
        save(inflated,white_avg);
    end
end