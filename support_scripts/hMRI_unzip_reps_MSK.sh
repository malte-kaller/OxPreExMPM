#!/usr/bin/env bash

# This script prepares MPM echoes from multiple repetitions for hMRI

# Source the project settings
source "project_settings.sh"

subj=$1
source $2

# create new folders for output
subDir=$procDIR/$subj/MPM_preprocessing/"$subj"_NIFTI
outDir=$subDir/SubjectDIR_RepetitionAverage

#Last step is to UnZip all the .nii.gz files created to hMRI to process
#fsl_sub -q veryshort.q -l $scriptDIR/logs/MPM/regrep
gunzip $outDir/MTwDIR/*nii.gz
#fsl_sub -q veryshort.q -l $scriptDIR/logs/MPM/regrep 
gunzip $outDir/PDwDIR/*nii.gz
#fsl_sub -q veryshort.q -l $scriptDIR/logs/MPM/regrep 
gunzip $outDir/T1wDIR/*nii.gz
# after running this, need to check

echo "===SCRIPT DONE==="
