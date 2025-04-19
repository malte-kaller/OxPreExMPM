#!/bin/bash

# bash-Matlab wrapper interface. 
# Purpose of the Script is to submit all subjects for conversion of dicom to nifti files using the context of the hMRI pipeline to create usuable json files for hMRI pipeline
# Need to be in script folder to run this script
# Source the project settings
source "project_settings.sh"

setting=$scriptDIR/project_settings.sh

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
  
#Step1=`fsl_sub -q short -l $scriptDIR/logs/MPM/ -N hMRIconvert bash $sup_scriptDIR/my_hMRI_DICOM_wrapper_MSK_EDicom.sh $subj`

outDIR="$procDIR/$subj/MPM_preprocessing"
rawDIR="$rawBruDIR/$subj"
logDIR="$scriptDIR/logs/MPM"

mkdir -p "$outDIR" "$logDIR"

# === Submit MATLAB conversion to the queue ===

Step1=$(fsl_sub -q short -l "$logDIR" -N hMRIconvert_${subj} \
  bash -c 'echo "[INFO] Converting DICOM for subject: '"$subj"'"
  matlab -nojvm -nodesktop -nosplash -r "try, hMRI_DICOM_wrapper_EDicom('\'''"$rawBruDIR/$subj"''\'','\'''"$procDIR/$subj/MPM_preprocessing"''\''); catch ME, disp(getReport(ME)); exit(1); end; exit(0);" > "'"$procDIR/$subj/MPM_preprocessing/hmri_convert_${subj}.log"'" 2>&1'
)

#======STEP 2: Register repetition =========
#This script registers repetion of scans to each other to avoid any artefacts

  echo "Job submitted for register repetition of scans for $subj";
  
Step2a=$(fsl_sub -q short -j ${Step1} -l "$scriptDIR/logs/MPM" \
  -N "SplitDicom_${subj}" \
  bash $sup_scriptDIR/SplitDicom.sh $subj)

Step2=$(fsl_sub -q short -j ${Step2a} -l "$scriptDIR/logs/MPM" \
  -N "RegisterReps_${subj}" \
  bash $sup_scriptDIR/register_repetitions_MSK_EDicom.sh $subj $MTfile $PDfile $T1file $setting)

#======STEP 3: Run the MPM caclulation via the hMRI pipeline =========
#Calculate parameters for the MPM processing

  echo "Job submitted caclulating MPM parameters $subj";

Step3=$(fsl_sub -q short -j ${Step2} -l $scriptDIR/logs/MPM -N hMRI_MPMproc_${subj} \
  bash $sup_scriptDIR/my_hMRI_wrapper_MSK.sh $subj $setting)

done

echo "Script done"
