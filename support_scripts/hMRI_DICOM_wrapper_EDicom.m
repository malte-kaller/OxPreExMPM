function hMRI_DICOM_wrapper(directory, outfolder)
    % Add Path to hMRI toolbox
   % addpath /vols/Scratch/gtn256/mri_scripts/scripts_MYRF22_noCA_Yingshi/toolbox/hMRI-Toolbox;
   % addpath /vols/Data/preclinical/Myelin_HJB/Projects/Pipeline_Test/project_scripts/RT_MYRD/preprocessing/toolbox/hMRI-Toolbox
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

    % Step 3: Split each 4D NIfTI file into separate 3D NIfTI files for each echo
    % Only process files in subdirectories of `outfolder`
    nifti_files = dir(fullfile(outfolder, '**', '*/', '*.nii'));

    for i = 1:length(nifti_files)
        nifti_path = fullfile(nifti_files(i).folder, nifti_files(i).name);
        
        % Define the subdirectory to save split files in the same structure as the original files
        relative_path = strrep(nifti_files(i).folder, directory, '');
        split_outfolder = fullfile(outfolder, relative_path);
        if ~exist(split_outfolder, 'dir')
            mkdir(split_outfolder);
        end

        % Load the 4D NIfTI file (each 4th dimension slice represents an echo)
        nifti_data = spm_vol(nifti_path);
        img_data = spm_read_vols(nifti_data);

        % Check if the data has 4 dimensions
        if ndims(img_data) ~= 4
            warning('NIfTI file %s is not 4D. Skipping this file.', nifti_path);
            continue;
        end

        % Number of echos (4th dimension)
        num_echos = size(img_data, 4);

        % Load JSON metadata if it exists and prepare for duplication
        json_path = [nifti_path(1:end-4) '.json'];
        if exist(json_path, 'file')
            original_json = jsondecode(fileread(json_path));
        else
            original_json = struct(); % Create an empty struct if no JSON exists
        end

        % Loop through each echo and save as a separate 3D NIfTI file and JSON
        for echo = 1:num_echos
            % Extract the echo-specific 3D volume
            echo_data = img_data(:, :, :, echo);

            % Create a new NIfTI header for each echo
            echo_vol = nifti_data(1);  % Copy original header for echo-specific file
            echo_vol.fname = fullfile(split_outfolder, sprintf('%s_echo_%04d.nii', nifti_files(i).name(1:end-4), echo));

            % Write the new NIfTI file for this echo
            spm_write_vol(echo_vol, echo_data);
            fprintf('Saved echo %d as %s\n', echo, echo_vol.fname);

            % Create a JSON file for each echo
            echo_json_path = fullfile(split_outfolder, sprintf('%s_echo_%04d.json', nifti_files(i).name(1:end-4), echo));
            echo_json = original_json;
            
            % Add "EchoTime" field in "acqpar" for each echo
            if isfield(echo_json, 'acqpar') && ~isempty(echo_json.acqpar)
                echo_json.acqpar{1}.EchoTime = echo;  % Add EchoTime as echo number
            else
                % Initialize acqpar if not present and add EchoTime
                echo_json.acqpar = {struct('EchoTime', echo)};
            end

            % Write the JSON file
            fid = fopen(echo_json_path, 'w');
            if fid == -1
                error('Cannot create JSON file: %s', echo_json_path);
            end
            fwrite(fid, jsonencode(echo_json, 'PrettyPrint', true));
            fclose(fid);
            fprintf('Saved JSON metadata for echo %d as %s\n', echo, echo_json_path);
        end

        % Optionally, delete the original 4D NIfTI file if no longer needed
        delete(nifti_path);
    end

    % Clean up
    clear matlabbatch;
    disp('------------------------ Splitting of NIfTI Files Complete ------------------------');
    disp(outfolder);
end
