#!/bin/bash

#This script creates the Mean B0 files of the subject 

#---DEFINE BASIC PARAMETERS FOR PROJECT------------------

# Source the project settings
source "project_settings.sh"

#--------------------------------------------------------

#For loop for each subject
subj=$1

dtiDir=$procDIR/$subj/DTI_processed

#===Processing B0 for specific pipline. Assuming B0

# Step 1: Extract the first and the seventeenth volumes
fslroi $dtiDir/data_gibbs_eddy.nii.gz $dtiDir/volume_0.nii.gz 0 1
fslroi $dtiDir/data_gibbs_eddy.nii.gz $dtiDir/volume_16.nii.gz 16 1

# Step 2: Merge the extracted volumes into a new 4D file
# (This step is optional for averaging just two volumes but included for completeness)
rm -f $dtiDir/merged_volumes.nii.gz
fslmerge -t $dtiDir/merged_volumes.nii.gz $dtiDir/volume_0.nii.gz $dtiDir/volume_16.nii.gz

# Step 3: Average the volumes
# Since you're only working with two volumes, you can directly average them without merging, but for demonstration:
fslmaths $dtiDir/merged_volumes.nii.gz -Tmean $dtiDir/B0_mean.nii.gz

#Adjust images accordingly
fslmaths $dtiDir/B0_mean.nii.gz -thr 0 $dtiDir/B0_mean.nii.gz
fslmaths $dtiDir/B0_mean.nii.gz -thrP 2 $dtiDir/B0_mean.nii.gz 

echo "done with $subj"

echo "done"



