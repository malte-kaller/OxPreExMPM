#!/bin/bash

# bash-Matlab wrapper interface. 
# Purpose of the Script is to submit all subjects for conversion of dicom to nifti files using the context of the hMRI pipeline to create usuable json files for hMRI pipeline
# Need to be in script folder to run this script
# Source the project settings
source "project_settings.sh"

setting=$scriptDIR/project_settings.sh

subjlist="20250224_084029_MYRD5_1b_MyReach_T2w_DTI_MPM_1_1"

#Add Matlab
#module add MATLAB
#module add spm
module add hMRI

#FSL tools
module add fsl
module add fsl_sub

#====BEFORE YOU RUN, CHECK THE NAMING OF THE SPECIFIC FILES FROM THE BRUKERS OUTPUT

#Check and Define the names of the Scans for the different modalities for the MPM scan
# DOUBLE CHECK NAMES MATCH; only include MT on
MTfile=mt_MGE_TR100_100um_FA6_MT_On
PDfile=mt_MGE_TR100_100um_FA6_PD
T1file=mt_MGE_TR100_100um_FA35_T1



#-------- Script submission below ---------

#======STEP 1: Convert all dicom to NIFTI========
#Call the other Script that will submit the job for each subject on the list. 
#This step takes all DICOM files from the raw brukers folder and converts them into NIFTI files via the SPM piline, which is required for the MPM process pipeline. 

for subj in $subjlist; do
 
  echo "Job submitted for converting files for $subj";
  
Step1=`fsl_sub -q short -l $scriptDIR/logs/MPM/ -N hMRIconvert bash $sup_scriptDIR/my_hMRI_DICOM_wrapper_MSK_EDicom.sh $subj`

#======STEP 2: Register repetition =========
#This script registers repetion of scans to each other to avoid any artefacts

  echo "Job submitted for register repetition of scans for $subj";
  
#Step2a=`fsl_sub -q short -l $scriptDIR/logs/MPM -N hMRIreg1 bash $sup_scriptDIR/SplitDicom.sh $subj $setting `

#Step2a=`fsl_sub -q short -j ${Step1} -l $scriptDIR/logs/MPM -N hMRIreg1 bash $sup_scriptDIR/SplitDicom.sh $subj`

#Step2=`fsl_sub -q short -j ${Step2a} -l $scriptDIR/logs/MPM -N hMRIreg2 bash $sup_scriptDIR/register_repetitions_MSK_EDicom.sh $subj $MTfile $PDfile $T1file $setting` # hMRIreg is the name of the job

#Step2=`fsl_sub -q short -l $scriptDIR/logs/MPM -N hMRIreg bash $sup_scriptDIR/register_repetitions_MSK_EDicom.sh $subj $MTfile $PDfile $T1file` # hMRIreg is the name of the job

#======STEP 3: Register repetition =========
#This scripts unzips the outputs of the previous output, required for the next step

#Step3=`fsl_sub -q short -j ${Step2} -l $scriptDIR/MPM/logs -N hMRIregzip bash hMRI_unzip_reps_MSK.sh $subj  `

#Step3=`fsl_sub -q short -j ${Step2} -l $scriptDIR/MPM/logs -N hMRIregzip bash $sup_scriptDIR/hMRI_unzip_reps_MSK.sh $subj $setting`

#======STEP 4: Run the MPM caclulation via the hMRI pipeline =========
#Calculate parameters for the MPM processing

  echo "Job submitted caclulating MPM parameters $subj";

#Step4=`fsl_sub -q long.q -j ${Step3} -l $scriptDIR/MPM/logs -N hMRI_MPMproc bash $sup_scriptDIR/my_hMRI_wrapper_MSK.sh` $scan

#Step4=`fsl_sub -q short -j ${Step3} -l $scriptDIR/logs/MPM -N hMRI_MPMproc bash $sup_scriptDIR/my_hMRI_wrapper_MSK.sh $subj`

#Step4=`fsl_sub -q short -l $scriptDIR/logs/MPM -N hMRI_MPMproc bash $sup_scriptDIR/my_hMRI_wrapper_MSK.sh $subj`

done

echo "Script done"
