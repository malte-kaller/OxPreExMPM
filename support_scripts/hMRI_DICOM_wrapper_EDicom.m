function hMRI_DICOM_wrapper(directory, outfolder)
    % Add Path to hMRI toolbox
addpath /cvmfs/software.fmrib.ox.ac.uk/eb/el9/software/hMRI/0.6.1-MATLAB-2024a/hMRI-toolbox-0.6.1

 % Step 1: Find all DICOM files
    List_of_all = dir(fullfile(directory, '**', '*.dcm'));
    DICOMFILES = {};
    for i = 1:length(List_of_all)
        DICOMFILES{i} = fullfile(List_of_all(i).folder, List_of_all(i).name);
    end
    DICOMFILES = DICOMFILES';

    % Echo all DICOM file paths
    disp('DICOM files to be processed:');
    for i = 1:length(DICOMFILES)
        disp(DICOMFILES{i});
    end

    % Step 2: DICOM conversion using hMRI toolbox
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    matlabbatch{1}.spm.tools.hmri.dicom.data = DICOMFILES;
    matlabbatch{1}.spm.tools.hmri.dicom.root = 'series';
    matlabbatch{1}.spm.tools.hmri.dicom.outdir = {outfolder};
    matlabbatch{1}.spm.tools.hmri.dicom.protfilter = '.*';
    matlabbatch{1}.spm.tools.hmri.dicom.convopts.format = 'nii';
    matlabbatch{1}.spm.tools.hmri.dicom.convopts.icedims = 0;
    matlabbatch{1}.spm.tools.hmri.dicom.convopts.metaopts.mformat = 'sep';
    spm_jobman('run', matlabbatch);

    % Wait for SPM processing to complete
    disp('------------------------ SPM DICOM Conversion Complete ------------------------');

