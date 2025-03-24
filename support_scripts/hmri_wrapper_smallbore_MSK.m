function hmri_wrapper_smallbore_MSK(directory,defaultsfiledir)

%Add Path to hMRI toolbox
%addpath  /home/fs0/mkaller/scratch/Postdoc_Data/Scripts/Precli_MPM/hMRI-Toolbox/
%addpath  /home/fs0/mkaller/scratch/Postdoc_Data/PreProcessMRI/MPM/AL_Data_Test3/Scripts/hMRI-toolbox/
%addpath /vols/Data/preclinical/Yingshi/MYFR_T2W_MPM_MTR_DTI_Summer22/NoCA/scripts_MYRF22_noCA_Yingshi_copied20240802/toolbox/hMRI-Toolbox/
addpath /cvmfs/software.fmrib.ox.ac.uk/eb/el9/software/hMRI/0.6.1-MATLAB-2024a/hMRI-toolbox-0.6.1


%B1 map files
B1map_struct=strcat(directory,filesep,'B1DIR',filesep,'B1_struct_registered.nii');
B1map_DAM=strcat(directory,filesep,'B1DIR',filesep,'B1map_DAM_registered.nii');
B1map={B1map_struct,B1map_DAM}';

%MTw files
MTwfiles=dir(strcat(directory,filesep,'MTwDIR',filesep,'*.nii'));
tf2=false(size(MTwfiles,1),1);
for k=1:size(MTwfiles)
    if strfind(MTwfiles(k).name(1:2),'._')==1
        tf2(k)=true;
    end
end
MTwfiles(tf2)=[];
MTwfilenames=cell(1);
for i=1:size(MTwfiles,1)
    MTwfilenames{i}=strcat(MTwfiles(i).folder,filesep,MTwfiles(i).name);
end
MTwfilenames=MTwfilenames';
% PDw files
PDwfiles=dir(strcat(directory,filesep,'PDwDIR',filesep,'*.nii'));
tf2=false(size(PDwfiles,1),1);
for k=1:size(PDwfiles)
    if strfind(PDwfiles(k).name(1:2),'._')==1
        tf2(k)=true;
    end
end
PDwfiles(tf2)=[];
PDwfilenames=cell(1);
for i=1:size(PDwfiles,1)
    PDwfilenames{i}=strcat(PDwfiles(i).folder,filesep,PDwfiles(i).name);
end
PDwfilenames=PDwfilenames';

%T1w files
T1wfiles=dir(strcat(directory,filesep,'T1wDIR',filesep,'*.nii'));
tf2=false(size(T1wfiles,1),1);
for k=1:size(T1wfiles)
    if strfind(T1wfiles(k).name(1:2),'._')==1
        tf2(k)=true;
    end
end
T1wfiles(tf2)=[];
T1wfilenames=cell(1);
for i=1:size(T1wfiles,1)
    T1wfilenames{i}=strcat(T1wfiles(i).folder,filesep,T1wfiles(i).name);
end
T1wfilenames=T1wfilenames';

%mkdir(strcat(directory,filesep,'hMRI_Results_B1'))
%clear matlabbatch
%matlabbatch{1}.spm.tools.hmri.hmri_config.hmri_setdef.customised = {strcat(defaultsfiledir,filesep,'hmri_local_defaults_smallbore_MSK.m')};
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.output.outdir = {strcat(directory,filesep,'hMRI_Results_B1')};
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.sensitivity.RF_us = '-';
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.b1_type.pre_processed_B1.b1input = B1map;
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.MT = MTwfilenames;
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.PD = PDwfilenames;
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.T1 = T1wfilenames;
%spm_jobman('run',matlabbatch);
%clear matlabbatch


%mkdir(strcat(directory,filesep,'hMRI_ResultsB1_DAM'))
%clear matlabbatch
%matlabbatch{1}.spm.tools.hmri.hmri_config.hmri_setdef.customised = {strcat(defaultsfiledir,filesep,'hmri_local_defaults_smallbore_MSK.m')};
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.output.outdir = {strcat(directory,filesep,'hMRI_ResultsB1_DAM')};
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.sensitivity.RF_us = '4';
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.b1_type.DAM.b1input = B1map;
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.b1_type.DAM.b1parameters.b1metadata = 'yes';
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.MT = MTwfilenames;
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.PD = PDwfilenames;
%matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.T1 = T1wfilenames;
%spm_jobman('run',matlabbatch);
%clear matlabbatch

mkdir(strcat(directory,filesep,'hMRI_Results_noB1mapping'))
clear matlabbatch
%spm('defaults','fmri'); %Added by MSK, as job was not running
%spm_jobman('initcfg'); %Added by MSK, as job was not running
matlabbatch{1}.spm.tools.hmri.hmri_config.hmri_setdef.customised = {strcat(defaultsfiledir,filesep,'hmri_local_defaults_smallbore_MSK.m')};
matlabbatch{2}.spm.tools.hmri.create_mpm.subj.output.outdir = {strcat(directory,filesep,'hMRI_Results_noB1mapping')};
matlabbatch{2}.spm.tools.hmri.create_mpm.subj.sensitivity.RF_none = '-';
matlabbatch{2}.spm.tools.hmri.create_mpm.subj.b1_type.no_B1_correction = 'noB1';
matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.MT = MTwfilenames;
matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.PD = PDwfilenames;
matlabbatch{2}.spm.tools.hmri.create_mpm.subj.raw_mpm.T1 = T1wfilenames;
spm_jobman('run',matlabbatch);
clear matlabbatch

